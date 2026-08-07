import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { MenuItem } from '../entities/menu-item.entity';

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
}
