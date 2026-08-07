import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { CartRepository } from './repositories/cart.repository';
import { Cart } from './entities/cart.entity';
import { CartItem } from './entities/cart-item.entity';
import { CartItemOption } from './entities/cart-item-option.entity';
import { AddCartItemDto } from './dto/add-cart-item.dto';
import { UpdateCartItemDto } from './dto/update-cart-item.dto';
import { PricingService } from '../pricing/pricing.service';

@Injectable()
export class CartsService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly carts: CartRepository,
    private readonly pricing: PricingService,
  ) {}

  async getActive(customerId: string, restaurantId: string): Promise<Cart> {
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
          expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 7),
        }),
      );
    }
    return cart;
  }

  async detail(customerId: string, restaurantId: string) {
    const cart = await this.getActive(customerId, restaurantId);
    const items = await this.dataSource.getRepository(CartItem).find({
      where: { cartId: cart.id },
      order: { createdAt: 'ASC' },
    });
    const options = items.length
      ? await this.dataSource
          .getRepository(CartItemOption)
          .createQueryBuilder('option')
          .where('option.cart_item_id IN (:...ids)', {
            ids: items.map((i) => i.id),
          })
          .getMany()
      : [];

    const subtotalMinor = items.reduce(
      (sum, item) => sum + Number(item.lineTotalMinor),
      0,
    );
    return { cart, items, options, subtotalMinor };
  }

  async addItem(customerId: string, restaurantId: string, dto: AddCartItemDto) {
    const cart = await this.getActive(customerId, restaurantId);
    const price = await this.pricing.calculate({
      menuItemId: dto.menuItemId,
      sizeId: dto.menuItemSizeId,
      optionChoiceIds: dto.optionChoiceIds,
      quantity: dto.quantity,
    });

    return this.dataSource.transaction(async (manager) => {
      const itemRepo = manager.getRepository(CartItem);
      const optionRepo = manager.getRepository(CartItemOption);
      const item = await itemRepo.save(
        itemRepo.create({
          cartId: cart.id,
          menuItemId: dto.menuItemId,
          menuItemSizeId: dto.menuItemSizeId,
          quantity: dto.quantity,
          itemNameSnapshot: dto.itemNameSnapshot,
          sizeNameSnapshot: dto.sizeNameSnapshot,
          baseUnitPriceMinor: price.basePriceMinor,
          optionsUnitPriceMinor: price.optionAdjustmentsMinor,
          unitPriceMinor: price.unitPriceMinor,
          lineTotalMinor: price.lineTotalMinor,
          specialInstructions: dto.specialInstructions,
          configurationHash: dto.configurationHash,
        }),
      );

      if (dto.options?.length) {
        await optionRepo.save(
          dto.options.map((option) =>
            optionRepo.create({
              cartItemId: item.id,
              optionGroupId: option.optionGroupId,
              optionChoiceId: option.optionChoiceId,
              ingredientId: option.ingredientId,
              action: option.action ?? 'add',
              optionNameSnapshot: option.optionNameSnapshot,
              quantity: option.quantity ?? 1,
              unitPriceAdjustmentMinor: option.unitPriceAdjustmentMinor ?? 0,
              totalPriceAdjustmentMinor: option.totalPriceAdjustmentMinor ?? 0,
            }),
          ),
        );
      }

      return item;
    });
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
      if (dto.quantity < 1)
        throw new BadRequestException('Quantity must be at least 1');
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

  async clear(cartId: string): Promise<void> {
    await this.dataSource.getRepository(CartItem).delete({ cartId });
  }
}
