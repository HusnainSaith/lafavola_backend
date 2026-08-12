import { BadRequestException, Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { requireEntity } from '../../common/utils/service-errors.util';
import { AddCartItemDto } from '../carts/dto/add-cart-item.dto';
import { CartsService } from '../carts/carts.service';
import { OrderItemOption } from '../orders/entities/order-item-option.entity';
import { OrderItem } from '../orders/entities/order-item.entity';
import { MenuItem } from '../menu/entities/menu-item.entity';
import { MenuItemSize } from '../menu/entities/menu-item-size.entity';
import { CreateFavoriteDto } from './dto/create-favorite.dto';
import { FavoriteRepository } from './repositories/favorite.repository';

@Injectable()
export class FavoritesService {
  constructor(
    private readonly favorites: FavoriteRepository,
    private readonly carts: CartsService,
    private readonly dataSource: DataSource,
  ) {}

  list(customerId: string) {
    return this.favorites.findMany({
      where: { customerId },
      order: { createdAt: 'DESC' },
    });
  }

  async create(customerId: string, dto: CreateFavoriteDto) {
    const configurationSnapshot = { ...(dto.configurationSnapshot ?? {}) };
    if (dto.menuItemId && !dto.sourceOrderItemId) {
      const item = await this.dataSource.getRepository(MenuItem).findOne({
        where: {
          id: dto.menuItemId,
          restaurantId: dto.restaurantId,
          isActive: true,
        },
      });
      if (!item || item.archivedAt) {
        throw new BadRequestException('Favorite menu item is not available');
      }
      if (!configurationSnapshot.menuItemSizeId) {
        const defaultSize = await this.dataSource
          .getRepository(MenuItemSize)
          .findOne({
            where: { menuItemId: dto.menuItemId, isActive: true },
            order: { displayOrder: 'ASC', basePriceMinor: 'ASC' },
          });
        if (!defaultSize) {
          throw new BadRequestException(
            'Favorite menu item has no available size',
          );
        }
        configurationSnapshot.menuItemSizeId = defaultSize.id;
      }
      const existing = await this.favorites.findOne({
        where: {
          customerId,
          restaurantId: dto.restaurantId,
          menuItemId: dto.menuItemId,
        },
      });
      if (existing) {
        existing.label = dto.label ?? existing.label;
        existing.configurationSnapshot = configurationSnapshot;
        return this.favorites.save(existing);
      }
    }
    return this.favorites.save(
      this.favorites.create({
        ...dto,
        customerId,
        configurationSnapshot,
      }),
    );
  }

  async remove(customerId: string, id: string): Promise<void> {
    const favorite = requireEntity(
      await this.favorites.findOne({ where: { id, customerId } }),
      'Favorite not found',
    );
    await this.favorites.deleteById(favorite.id);
  }

  async addToCart(customerId: string, id: string, quantity: number) {
    const favorite = requireEntity(
      await this.favorites.findOne({ where: { id, customerId } }),
      'Favorite not found',
    );

    let addition: AddCartItemDto;
    if (favorite.sourceOrderItemId) {
      const source = requireEntity(
        await this.dataSource.getRepository(OrderItem).findOne({
          where: { id: favorite.sourceOrderItemId, order: { customerId } },
          relations: { order: true },
        }),
        'Favorite source order item not found',
      );
      if (!source.menuItemId)
        throw new BadRequestException(
          'Favorite menu item is no longer available',
        );
      const options = await this.dataSource
        .getRepository(OrderItemOption)
        .find({ where: { orderItemId: source.id } });
      addition = {
        menuItemId: source.menuItemId,
        menuItemSizeId: source.menuItemSizeId,
        quantity,
        specialInstructions: source.specialInstructions,
        options: options.map((option) => ({
          optionGroupId: option.optionGroupId,
          optionChoiceId: option.optionChoiceId,
          ingredientId: option.ingredientId,
          action: option.action as 'add' | 'remove' | 'replace',
          quantity: Number(option.quantity),
        })),
      };
    } else {
      if (!favorite.menuItemId)
        throw new BadRequestException('Favorite has no menu item');
      const snapshot =
        favorite.configurationSnapshot as Partial<AddCartItemDto>;
      addition = {
        menuItemId: favorite.menuItemId,
        menuItemSizeId: snapshot.menuItemSizeId,
        options: snapshot.options,
        specialInstructions: snapshot.specialInstructions,
        quantity,
      };
    }

    return this.carts.addItemsAtomic(customerId, favorite.restaurantId, [
      addition,
    ]);
  }
}
