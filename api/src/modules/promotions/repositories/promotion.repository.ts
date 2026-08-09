import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Promotion } from '../entities/promotion.entity';

@Injectable()
export class PromotionRepository extends BaseRepository<Promotion> {
  constructor(dataSource: DataSource) {
    super(dataSource, Promotion);
  }

  findActiveForRestaurant(restaurantId: string): Promise<Promotion[]> {
    return this.repository
      .createQueryBuilder('promotion')
      .where('promotion.restaurant_id = :restaurantId', { restaurantId })
      .andWhere('promotion.is_active = true')
      .andWhere('promotion.starts_at <= NOW()')
      .andWhere('(promotion.ends_at IS NULL OR promotion.ends_at > NOW())')
      .orderBy('promotion.priority', 'DESC')
      .getMany();
  }
}
