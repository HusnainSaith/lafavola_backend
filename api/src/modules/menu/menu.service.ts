import { Injectable, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { requireEntity } from '../../common/utils/service-errors.util';
import { CreateMenuItemDto } from './dto/create-menu-item.dto';
import { UpdateMenuItemDto } from './dto/update-menu-item.dto';
import { MenuQueryDto } from './dto/menu-query.dto';
import { MenuItemSize } from './entities/menu-item-size.entity';
import { MenuItem } from './entities/menu-item.entity';
import { MenuItemRepository } from './repositories/menu-item.repository';

@Injectable()
export class MenuService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly items: MenuItemRepository,
  ) {}

  list(query: MenuQueryDto) {
    return this.items.findPublicMenu(query);
  }

  search(restaurantId: string, query: string): Promise<MenuItem[]> {
    return this.items.searchActive(restaurantId, query.trim());
  }

  async detail(id: string): Promise<MenuItem> {
    const item = await this.items.findOne({
      where: { id, isActive: true },
      relations: {
        category: true,
        imageAsset: true,
        restaurant: true,
        sizes: true,
        ingredients: { ingredient: true },
      },
    });
    if (
      item &&
      (!item.restaurant?.isActive ||
        (item.availableFrom && item.availableFrom > new Date()) ||
        (item.availableUntil && item.availableUntil <= new Date()))
    ) {
      throw new NotFoundException('Menu item not found');
    }
    return requireEntity(item, 'Menu item not found');
  }

  async create(dto: CreateMenuItemDto): Promise<MenuItem> {
    return this.dataSource.transaction(async (manager) => {
      const itemRepo = manager.getRepository(MenuItem);
      const sizeRepo = manager.getRepository(MenuItemSize);

      const item = await itemRepo.save(
        itemRepo.create({
          restaurantId: dto.restaurantId,
          categoryId: dto.categoryId,
          name: dto.name,
          slug: dto.slug,
          description: dto.description,
          imageAssetId: dto.imageAssetId,
          itemType: dto.itemType,
          calories: dto.calories,
          preparationMinutes: dto.preparationMinutes ?? 15,
          isVegetarian: dto.isVegetarian ?? false,
          isVegan: dto.isVegan ?? false,
          isGlutenFree: dto.isGlutenFree ?? false,
          isSpicy: dto.isSpicy ?? false,
          isPopular: dto.isPopular ?? false,
          popularityScore: '0',
          isActive: dto.isActive ?? true,
        }),
      );

      if (dto.sizes?.length) {
        await sizeRepo.save(
          dto.sizes.map((size) =>
            sizeRepo.create({
              menuItemId: item.id,
              sizeCode: size.sizeCode,
              displayName: size.displayName,
              basePriceMinor: size.basePriceMinor,
              calories: size.calories,
              displayOrder: size.displayOrder ?? 0,
              isActive: size.isActive ?? true,
            }),
          ),
        );
      }

      return itemRepo.findOneOrFail({ where: { id: item.id } });
    });
  }

  async update(id: string, dto: UpdateMenuItemDto): Promise<MenuItem> {
    const item = await this.items.findById(id);
    if (!item) throw new NotFoundException('Menu item not found');
    Object.assign(item, dto);
    return this.items.save(item);
  }

  async archive(id: string): Promise<void> {
    const item = await this.detail(id);
    item.isActive = false;
    item.archivedAt = new Date();
    await this.items.save(item);
  }
}
