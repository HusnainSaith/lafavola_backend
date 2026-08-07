import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Coupon } from '../entities/coupon.entity';

@Injectable()
export class CouponRepository extends BaseRepository<Coupon> {
  constructor(dataSource: DataSource) {
    super(dataSource, Coupon);
  }

  findActiveByCode(restaurantId: string, code: string): Promise<Coupon | null> {
    return this.repository
      .createQueryBuilder('coupon')
      .where('coupon.restaurant_id = :restaurantId', { restaurantId })
      .andWhere('UPPER(coupon.code) = UPPER(:code)', { code })
      .andWhere('coupon.is_active = true')
      .andWhere('(coupon.starts_at IS NULL OR coupon.starts_at <= NOW())')
      .andWhere('(coupon.expires_at IS NULL OR coupon.expires_at > NOW())')
      .getOne();
  }
}
