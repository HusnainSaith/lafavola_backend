import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource, EntityManager, In } from 'typeorm';
import { MenuItemSize } from '../menu/entities/menu-item-size.entity';
import { MenuItem } from '../menu/entities/menu-item.entity';
import { OptionChoice } from '../option-groups/entities/option-choice.entity';
import { PricingService } from '../pricing/pricing.service';
import { Restaurant } from '../restaurants/entities/restaurant.entity';
import { AddCartItemDto } from './dto/add-cart-item.dto';
import { UpdateCartItemDto } from './dto/update-cart-item.dto';
import { CartItemOption } from './entities/cart-item-option.entity';
import { CartItem } from './entities/cart-item.entity';
import { Cart } from './entities/cart.entity';
import { CartRepository } from './repositories/cart.repository';

@Injectable()
export class CartsService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly carts: CartRepository,
    private readonly pricing: PricingService,
  ) {}

  async getActive(customerId: string, restaurantId?: string): Promise<Cart> {
    restaurantId = await this.resolveRestaurantId(restaurantId);
    let cart = await this.carts.findOne({
      where: { customerId, restaurantId, status: 'active' },
    });

    if (!cart) {
      cart = await this.carts.save(
        this.carts.create({
          customerId,
          restaurantId,
          status: 'active',
          currency: 'EUR',
          expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        }),
      );
    }

    return cart;
  }

  async detail(customerId: string, restaurantId?: string) {
    const cart = await this.getActive(customerId, restaurantId);
    return this.loadCart(cart);
  }

  async detailById(customerId: string, cartId: string) {
    const cart = await this.carts.findOne({
      where: { id: cartId, customerId, status: 'active' },
    });

    if (!cart) {
      throw new NotFoundException('Active cart not found');
    }

    return this.loadCart(cart);
  }

  private async loadCart(cart: Cart) {
    const items = await this.dataSource.getRepository(CartItem).find({
      where: { cartId: cart.id },
      order: { createdAt: 'ASC' },
    });

    const options = items.length
      ? await this.dataSource
          .getRepository(CartItemOption)
          .createQueryBuilder('option')
          .where('option.cart_item_id IN (:...ids)', {
            ids: items.map((item) => item.id),
          })
          .getMany()
      : [];

    const subtotalMinor = items.reduce(
      (sum, item) => sum + Number(item.lineTotalMinor),
      0,
    );

    return { cart, items, options, subtotalMinor };
  }

  async addItem(
    customerId: string,
    restaurantId: string | undefined,
    dto: AddCartItemDto,
  ) {
    restaurantId = await this.resolveRestaurantId(restaurantId);
    const cart = await this.getActive(customerId, restaurantId);
    const itemRepo = this.dataSource.getRepository(MenuItem);
    const sizeRepo = this.dataSource.getRepository(MenuItemSize);
    const choiceRepo = this.dataSource.getRepository(OptionChoice);

    const menuItem = await itemRepo.findOne({
      where: { id: dto.menuItemId, restaurantId, isActive: true },
    });

    if (!menuItem) {
      throw new NotFoundException('Menu item not found');
    }

    const size = dto.menuItemSizeId
      ? await sizeRepo.findOne({
          where: {
            id: dto.menuItemSizeId,
            menuItemId: dto.menuItemId,
            isActive: true,
          },
        })
      : null;

    if (dto.menuItemSizeId && !size) {
      throw new BadRequestException('Invalid menu item size');
    }

    const optionChoiceIds = [
      ...new Set(
        (dto.options ?? [])
          .map((option) => option.optionChoiceId)
          .filter((id): id is string => Boolean(id)),
      ),
    ];

    const price = await this.pricing.calculate({
      menuItemId: dto.menuItemId,
      sizeId: dto.menuItemSizeId,
      optionChoiceIds,
      options: dto.options,
      quantity: dto.quantity,
    });

    const choices = optionChoiceIds.length
      ? await choiceRepo
          .createQueryBuilder('choice')
          .where('choice.id IN (:...ids)', { ids: optionChoiceIds })
          .getMany()
      : [];

    const choiceById = new Map(choices.map((choice) => [choice.id, choice]));

    return this.dataSource.transaction(async (manager) => {
      const cartItemRepo = manager.getRepository(CartItem);
      const optionRepo = manager.getRepository(CartItemOption);

      const item = await cartItemRepo.save(
        cartItemRepo.create({
          cartId: cart.id,
          menuItemId: dto.menuItemId,
          menuItemSizeId: dto.menuItemSizeId,
          quantity: dto.quantity,
          itemNameSnapshot: menuItem.name,
          sizeNameSnapshot: size?.displayName,
          baseUnitPriceMinor: price.basePriceMinor,
          optionsUnitPriceMinor: price.optionAdjustmentsMinor,
          unitPriceMinor: price.unitPriceMinor,
          lineTotalMinor: price.lineTotalMinor,
          specialInstructions: dto.specialInstructions,
          configurationHash: this.configurationHash(dto),
        }),
      );

      if (dto.options?.length) {
        const options = dto.options.map((option) => {
          const choice = option.optionChoiceId
            ? choiceById.get(option.optionChoiceId)
            : undefined;
          const quantity = option.quantity ?? 1;
          const unitAdjustment = Number(choice?.priceAdjustmentMinor ?? 0);

          return optionRepo.create({
            cartItemId: item.id,
            optionGroupId: option.optionGroupId,
            optionChoiceId: option.optionChoiceId,
            ingredientId: option.ingredientId,
            action: option.action ?? 'add',
            optionNameSnapshot:
              choice?.name ??
              (option.action === 'remove'
                ? 'Removed ingredient'
                : 'Custom option'),
            quantity: String(quantity),
            unitPriceAdjustmentMinor: unitAdjustment,
            totalPriceAdjustmentMinor: unitAdjustment * quantity,
          });
        });

        await optionRepo.save(options);
      }

      return item;
    });
  }

  private configurationHash(dto: AddCartItemDto): string {
    const normalized = JSON.stringify({
      menuItemId: dto.menuItemId,
      menuItemSizeId: dto.menuItemSizeId ?? null,
      options: (dto.options ?? [])
        .map((option) => ({
          optionGroupId: option.optionGroupId ?? null,
          optionChoiceId: option.optionChoiceId ?? null,
          ingredientId: option.ingredientId ?? null,
          action: option.action ?? 'add',
          quantity: option.quantity ?? 1,
        }))
        .sort((a, b) => JSON.stringify(a).localeCompare(JSON.stringify(b))),
    });

    let hash = 2166136261;
    for (let index = 0; index < normalized.length; index += 1) {
      hash ^= normalized.charCodeAt(index);
      hash = Math.imul(hash, 16777619);
    }

    return (hash >>> 0).toString(16).padStart(8, '0');
  }

  async updateItem(customerId: string, itemId: string, dto: UpdateCartItemDto) {
    const repo = this.dataSource.getRepository(CartItem);
    const item = await repo.findOne({
      where: { id: itemId },
      relations: { cart: true },
    });

    if (!item || item.cart.customerId !== customerId) {
      throw new NotFoundException('Cart item not found');
    }

    if (dto.quantity !== undefined) {
      if (dto.quantity < 1) {
        throw new BadRequestException('Quantity must be at least 1');
      }
      item.quantity = dto.quantity;
      item.lineTotalMinor = Number(item.unitPriceMinor) * dto.quantity;
    }

    if (dto.specialInstructions !== undefined) {
      item.specialInstructions = dto.specialInstructions;
    }

    return repo.save(item);
  }

  async removeItem(customerId: string, itemId: string): Promise<void> {
    const repo = this.dataSource.getRepository(CartItem);
    const item = await repo.findOne({
      where: { id: itemId },
      relations: { cart: true },
    });

    if (!item || item.cart.customerId !== customerId) {
      throw new NotFoundException('Cart item not found');
    }

    await repo.delete(item.id);
  }

  async clear(customerId: string, restaurantId?: string): Promise<void> {
    restaurantId = await this.resolveRestaurantId(restaurantId);
    const cart = await this.carts.findOne({
      where: { customerId, restaurantId, status: 'active' },
    });
    if (cart) {
      await this.dataSource.getRepository(CartItem).delete({ cartId: cart.id });
    }
  }

  async addItemsAtomic(
    customerId: string,
    restaurantId: string | undefined,
    additions: AddCartItemDto[],
  ) {
    restaurantId = await this.resolveRestaurantId(restaurantId);
    return this.dataSource.transaction(async (manager) => {
      const menuItemIds = [
        ...new Set(additions.map((item) => item.menuItemId)),
      ];
      const sizeIds = [
        ...new Set(
          additions
            .map((item) => item.menuItemSizeId)
            .filter((id): id is string => Boolean(id)),
        ),
      ];
      const choiceIds = [
        ...new Set(
          additions.flatMap((item) =>
            (item.options ?? [])
              .map((option) => option.optionChoiceId)
              .filter((id): id is string => Boolean(id)),
          ),
        ),
      ];
      const ingredientIds = [
        ...new Set(
          additions.flatMap((item) =>
            (item.options ?? [])
              .map((option) => option.ingredientId)
              .filter((id): id is string => Boolean(id)),
          ),
        ),
      ];
      await manager.query(
        'SELECT id FROM menu_items WHERE id = ANY($1::uuid[]) FOR UPDATE',
        [menuItemIds],
      );
      if (sizeIds.length)
        await manager.query(
          'SELECT id FROM menu_item_sizes WHERE id = ANY($1::uuid[]) FOR UPDATE',
          [sizeIds],
        );
      if (choiceIds.length)
        await manager.query(
          'SELECT id FROM option_choices WHERE id = ANY($1::uuid[]) FOR UPDATE',
          [choiceIds],
        );
      if (ingredientIds.length)
        await manager.query(
          'SELECT id FROM ingredients WHERE id = ANY($1::uuid[]) FOR UPDATE',
          [ingredientIds],
        );
      await manager.query(
        'SELECT id FROM menu_item_option_groups WHERE menu_item_id = ANY($1::uuid[]) FOR UPDATE',
        [menuItemIds],
      );

      const menuItems = await manager.getRepository(MenuItem).findBy({
        id: In(menuItemIds),
        restaurantId,
        isActive: true,
      });
      const menuById = new Map(menuItems.map((item) => [item.id, item]));
      const sizes = sizeIds.length
        ? await manager.getRepository(MenuItemSize).findBy({ id: In(sizeIds) })
        : [];
      const sizeById = new Map(sizes.map((size) => [size.id, size]));
      const choices = choiceIds.length
        ? await manager
            .getRepository(OptionChoice)
            .findBy({ id: In(choiceIds) })
        : [];
      const choiceById = new Map(choices.map((choice) => [choice.id, choice]));
      const priced: Array<{
        dto: AddCartItemDto;
        price: Awaited<ReturnType<PricingService['calculate']>>;
      }> = [];
      for (const dto of additions) {
        const price = await this.pricing.calculate({
          menuItemId: dto.menuItemId,
          sizeId: dto.menuItemSizeId,
          quantity: dto.quantity,
          options: dto.options,
        });
        priced.push({ dto, price });
      }

      const cartRepo = manager.getRepository(Cart);
      let cart = await cartRepo
        .createQueryBuilder('cart')
        .setLock('pessimistic_write')
        .where('cart.customer_id = :customerId', { customerId })
        .andWhere('cart.restaurant_id = :restaurantId', { restaurantId })
        .andWhere('cart.status = :status', { status: 'active' })
        .getOne();
      if (!cart) {
        cart = await cartRepo.save(
          cartRepo.create({
            customerId,
            restaurantId,
            status: 'active',
            currency: 'EUR',
            expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          }),
        );
      }
      const itemRepo = manager.getRepository(CartItem);
      const optionRepo = manager.getRepository(CartItemOption);
      for (const { dto, price } of priced) {
        const menuItem = menuById.get(dto.menuItemId);
        if (!menuItem)
          throw new BadRequestException('Menu item is unavailable');
        const size = dto.menuItemSizeId
          ? sizeById.get(dto.menuItemSizeId)
          : undefined;
        const item = await itemRepo.save(
          itemRepo.create({
            cartId: cart.id,
            menuItemId: dto.menuItemId,
            menuItemSizeId: dto.menuItemSizeId,
            quantity: dto.quantity,
            itemNameSnapshot: menuItem.name,
            sizeNameSnapshot: size?.displayName,
            baseUnitPriceMinor: price.basePriceMinor,
            optionsUnitPriceMinor: price.optionAdjustmentsMinor,
            unitPriceMinor: price.unitPriceMinor,
            lineTotalMinor: price.lineTotalMinor,
            specialInstructions: dto.specialInstructions,
            configurationHash: this.configurationHash(dto),
          }),
        );
        if (dto.options?.length) {
          await optionRepo.save(
            dto.options.map((option) => {
              const choice = option.optionChoiceId
                ? choiceById.get(option.optionChoiceId)
                : undefined;
              const quantity = option.quantity ?? 1;
              const adjustment = Number(choice?.priceAdjustmentMinor ?? 0);
              return optionRepo.create({
                cartItemId: item.id,
                optionGroupId: option.optionGroupId,
                optionChoiceId: option.optionChoiceId,
                ingredientId: option.ingredientId,
                action: option.action ?? 'add',
                optionNameSnapshot: choice?.name ?? 'Custom option',
                quantity: String(quantity),
                unitPriceAdjustmentMinor: adjustment,
                totalPriceAdjustmentMinor: adjustment * quantity,
              });
            }),
          );
        }
      }
      return this.loadCartWithManager(manager, cart);
    });
  }

  private async loadCartWithManager(manager: EntityManager, cart: Cart) {
    const items = await manager.getRepository(CartItem).find({
      where: { cartId: cart.id },
      order: { createdAt: 'ASC' },
    });
    const options = items.length
      ? await manager.getRepository(CartItemOption).findBy({
          cartItemId: In(items.map((item) => item.id)),
        })
      : [];
    return {
      cart,
      items,
      options,
      subtotalMinor: items.reduce(
        (sum, item) => sum + Number(item.lineTotalMinor),
        0,
      ),
    };
  }

  private async resolveRestaurantId(restaurantId?: string): Promise<string> {
    if (restaurantId) return restaurantId;

    const restaurant = await this.dataSource.getRepository(Restaurant).findOne({
      where: { isActive: true },
      order: { createdAt: 'ASC' },
    });
    if (!restaurant) {
      throw new NotFoundException('Active restaurant is not configured');
    }
    return restaurant.id;
  }
}
