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
    return this.repository.findMany({
      order: { createdAt: 'DESC' },
    });
  }

  async findById(id: string): Promise<Coupon> {
    return requireEntity(
      await this.repository.findById(id),
      'Coupon record not found',
    );
  }

  create(dto: CreateCouponDto): Promise<Coupon> {
    return this.repository.save(
      this.repository.create({
        restaurantId: dto.restaurantId,
        promotionId: dto.promotionId,
        code: dto.code.trim().toUpperCase(),
        description: dto.description,
        discountType: dto.discountType,
        discountValue: dto.discountValue ?? 0,
        minOrderMinor: dto.minOrderMinor ?? 0,
        maxDiscountMinor: dto.maxDiscountMinor,
        startsAt: dto.startsAt
          ? new Date(dto.startsAt)
          : undefined,
        expiresAt: dto.expiresAt
          ? new Date(dto.expiresAt)
          : undefined,
        totalUsageLimit: dto.totalUsageLimit,
        perCustomerLimit: dto.perCustomerLimit,
        isActive: dto.isActive ?? true,
      }),
    );
  }

  async update(
    id: string,
    dto: UpdateCouponDto,
  ): Promise<Coupon> {
    const entity = await this.findById(id);

    Object.assign(entity, {
      ...dto,
      code: dto.code
        ? dto.code.trim().toUpperCase()
        : entity.code,
      startsAt: dto.startsAt
        ? new Date(dto.startsAt)
        : entity.startsAt,
      expiresAt: dto.expiresAt
        ? new Date(dto.expiresAt)
        : entity.expiresAt,
    });

    return this.repository.save(entity);
  }

  async remove(id: string): Promise<void> {
    const entity = await this.findById(id);
    entity.isActive = false;
    await this.repository.save(entity);
  }
}
