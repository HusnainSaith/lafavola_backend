import { Injectable } from '@nestjs/common';
import { CouponRepository } from './repositories/coupon.repository';
import { Coupon } from './entities/coupon.entity';
import { CreateCouponDto } from './dto/create-coupon.dto';
import { UpdateCouponDto } from './dto/update-coupon.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class CouponsService {
  constructor(private readonly repository: CouponRepository) {}

  findAll(): Promise<Coupon[]> {
    return this.repository.findMany({ order: { createdAt: 'DESC' } });
  }

  async findById(id: string): Promise<Coupon> {
    return requireEntity(
      await this.repository.findById(id),
      'Coupons record not found',
    );
  }

  create(dto: CreateCouponDto): Promise<Coupon> {
    return this.repository.save(this.repository.create(dto as Partial<Coupon>));
  }

  async update(id: string, dto: UpdateCouponDto): Promise<Coupon> {
    const entity = await this.findById(id);
    Object.assign(entity, dto);
    return this.repository.save(entity);
  }

  async remove(id: string): Promise<void> {
    const entity = await this.findById(id);
    (entity as any).isActive = false;
    await this.repository.save(entity);
  }
}
