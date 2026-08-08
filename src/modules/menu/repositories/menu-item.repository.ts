import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { MenuItem } from '../entities/menu-item.entity';
import { MenuQueryDto, MenuSort } from '../dto/menu-query.dto';

@Injectable()
export class MenuItemRepository extends BaseRepository<MenuItem> {
  constructor(dataSource: DataSource) {
    super(dataSource, MenuItem);
  }

  searchActive(restaurantId: string, search: string): Promise<MenuItem[]> {
    return this.repository
      .createQueryBuilder('item')
      .where('item.restaurant_id = :restaurantId', { restaurantId })
      .andWhere('item.is_active = true')
      .andWhere('item.archived_at IS NULL')
      .andWhere('(item.name ILIKE :search OR item.description ILIKE :search)', {
        search: `%${search}%`,
      })
      .orderBy('item.popularity_score', 'DESC')
      .getMany();
  }

  async findPublicMenu(query: MenuQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const qb = this.repository
      .createQueryBuilder('item')
      .innerJoinAndSelect(
        'item.restaurant',
        'restaurant',
        'restaurant.is_active = true',
      )
      .leftJoinAndSelect('item.category', 'category')
      .leftJoinAndSelect('item.imageAsset', 'image')
      .leftJoinAndSelect('item.sizes', 'size', 'size.is_active = true')
      .leftJoinAndSelect('item.ingredients', 'menuIngredient')
      .leftJoinAndSelect('menuIngredient.ingredient', 'ingredient')
      .where('item.is_active = true')
      .andWhere('item.archived_at IS NULL')
      .andWhere('(item.available_from IS NULL OR item.available_from <= NOW())')
      .andWhere(
        '(item.available_until IS NULL OR item.available_until > NOW())',
      );

    if (query.restaurantId)
      qb.andWhere('item.restaurant_id = :restaurantId', {
        restaurantId: query.restaurantId,
      });
    if (query.categoryId)
      qb.andWhere('item.category_id = :categoryId', {
        categoryId: query.categoryId,
      });
    if (query.ingredientId)
      qb.andWhere('menuIngredient.ingredient_id = :ingredientId', {
        ingredientId: query.ingredientId,
      });
    if (query.search)
      qb.andWhere(
        '(item.name ILIKE :search OR item.description ILIKE :search OR ingredient.name ILIKE :search)',
        { search: `%${query.search.trim()}%` },
      );
    if (query.minPriceMinor !== undefined)
      qb.andWhere('size.base_price_minor >= :minPrice', {
        minPrice: query.minPriceMinor,
      });
    if (query.maxPriceMinor !== undefined)
      qb.andWhere('size.base_price_minor <= :maxPrice', {
        maxPrice: query.maxPriceMinor,
      });
    if (query.vegetarian !== undefined)
      qb.andWhere('item.is_vegetarian = :vegetarian', {
        vegetarian: query.vegetarian,
      });
    if (query.vegan !== undefined)
      qb.andWhere('item.is_vegan = :vegan', { vegan: query.vegan });
    if (query.glutenFree !== undefined)
      qb.andWhere('item.is_gluten_free = :glutenFree', {
        glutenFree: query.glutenFree,
      });
    if (query.spicy !== undefined)
      qb.andWhere('item.is_spicy = :spicy', { spicy: query.spicy });
    if (query.popular !== undefined)
      qb.andWhere('item.is_popular = :popular', { popular: query.popular });

    if (query.sort === MenuSort.NEWEST) qb.orderBy('item.createdAt', 'DESC');
    else if (query.sort === MenuSort.PRICE_ASC)
      qb.orderBy('size.basePriceMinor', 'ASC');
    else if (query.sort === MenuSort.PRICE_DESC)
      qb.orderBy('size.basePriceMinor', 'DESC');
    else
      qb.orderBy('item.popularityScore', 'DESC').addOrderBy(
        'item.createdAt',
        'DESC',
      );

    const [items, total] = await qb
      .distinct(true)
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();
    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }
}
