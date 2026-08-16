import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { requireEntity } from '../../common/utils/service-errors.util';
import { DataSource } from 'typeorm';
import { Restaurant } from '../restaurants/entities/restaurant.entity';
import { StaffMember } from '../staff/entities/staff-member.entity';
import { CreateCouponDto } from './dto/create-coupon.dto';
import { UpdateCouponDto } from './dto/update-coupon.dto';
import { ValidateCouponDto } from './dto/validate-coupon.dto';
import { Coupon } from './entities/coupon.entity';
import { CouponRedemption } from './entities/coupon-redemption.entity';
import { CouponRepository } from './repositories/coupon.repository';

@Injectable()
export class CouponsService {
  constructor(
    private readonly repository: CouponRepository,
    private readonly dataSource: DataSource,
  ) {}

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

  async create(dto: CreateCouponDto, actorUserId: string): Promise<Coupon> {
    const restaurantId = await this.restaurantForActor(actorUserId);
    if (dto.restaurantId !== restaurantId) {
      throw new NotFoundException('Restaurant not found');
    }
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
        startsAt: dto.startsAt ? new Date(dto.startsAt) : undefined,
        expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : undefined,
        totalUsageLimit: dto.totalUsageLimit,
        perCustomerLimit: dto.perCustomerLimit,
        isActive: dto.isActive ?? true,
      }),
    );
  }

  async update(
    id: string,
    dto: UpdateCouponDto,
    actorUserId: string,
  ): Promise<Coupon> {
    const restaurantId = await this.restaurantForActor(actorUserId);
    const entity = await this.repository.findOne({
      where: { id, restaurantId },
    });
    if (!entity) throw new NotFoundException('Coupon record not found');
    if (dto.restaurantId && dto.restaurantId !== restaurantId) {
      throw new NotFoundException('Restaurant not found');
    }

    Object.assign(entity, {
      ...dto,
      code: dto.code ? dto.code.trim().toUpperCase() : entity.code,
      startsAt: dto.startsAt ? new Date(dto.startsAt) : entity.startsAt,
      expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : entity.expiresAt,
    });

    return this.repository.save(entity);
  }

  async remove(id: string, actorUserId: string): Promise<void> {
    const restaurantId = await this.restaurantForActor(actorUserId);
    const entity = await this.repository.findOne({
      where: { id, restaurantId },
    });
    if (!entity) throw new NotFoundException('Coupon record not found');
    entity.isActive = false;
    await this.repository.save(entity);
  }

  private async restaurantForActor(actorUserId: string) {
    const staff = await this.dataSource.getRepository(StaffMember).findOne({
      where: { userId: actorUserId, isActive: true },
      select: { restaurantId: true },
    });
    if (!staff) throw new NotFoundException('Staff member not found');
    return staff.restaurantId;
  }

  /**
   * Customer-facing coupon validation and discount preview. Mirrors the exact
   * validation rules enforced at checkout (active, time window, minimum order,
   * discount type and maximum discount) so the customer app can resolve a code
   * before the final checkout call instead of deferring it with a warning.
   */
  async validate(dto: ValidateCouponDto) {
    const restaurantId =
      dto.restaurantId ?? (await this.resolveActiveRestaurantId());
    const coupon = await this.dataSource
      .getRepository(Coupon)
      .createQueryBuilder('coupon')
      .where('coupon.restaurant_id = :restaurantId', { restaurantId })
      .andWhere('LOWER(coupon.code) = LOWER(:code)', { code: dto.code })
      .andWhere('coupon.is_active = true')
      .andWhere('(coupon.starts_at IS NULL OR coupon.starts_at <= NOW())')
      .andWhere('(coupon.expires_at IS NULL OR coupon.expires_at > NOW())')
      .getOne();

    if (!coupon) throw new BadRequestException('Coupon is invalid or expired');

    const subtotalMinor = dto.subtotalMinor ?? 0;
    const discountMinor = this.computeDiscount(coupon, subtotalMinor);
    const applies = subtotalMinor >= Number(coupon.minOrderMinor ?? 0);

    return {
      code: coupon.code,
      valid: true,
      applies,
      discountType: coupon.discountType,
      discountValue: coupon.discountValue,
      minOrderMinor: coupon.minOrderMinor,
      maxDiscountMinor: coupon.maxDiscountMinor ?? null,
      subtotalMinor,
      discountMinor,
    };
  }

  async listForCustomer(customerId: string) {
    const restaurantId = await this.resolveActiveRestaurantId();
    const coupons = await this.dataSource
      .getRepository(Coupon)
      .createQueryBuilder('coupon')
      .where('coupon.restaurant_id = :restaurantId', { restaurantId })
      .andWhere('coupon.is_active = true')
      .andWhere('(coupon.starts_at IS NULL OR coupon.starts_at <= NOW())')
      .andWhere('(coupon.expires_at IS NULL OR coupon.expires_at > NOW())')
      .orderBy('coupon.created_at', 'DESC')
      .getMany();

    if (!coupons.length) return [];

    const ids = coupons.map((coupon) => coupon.id);
    const redemptionRepo = this.dataSource.getRepository(CouponRedemption);
    const totalRows = (await redemptionRepo
      .createQueryBuilder('redemption')
      .select('redemption.coupon_id', 'couponId')
      .addSelect('COUNT(*)', 'count')
      .where('redemption.coupon_id IN (:...ids)', { ids })
      .groupBy('redemption.coupon_id')
      .getRawMany()) as Array<{ couponId: string; count: string }>;
    const customerRows = (await redemptionRepo
      .createQueryBuilder('redemption')
      .select('redemption.coupon_id', 'couponId')
      .addSelect('COUNT(*)', 'count')
      .where('redemption.coupon_id IN (:...ids)', { ids })
      .andWhere('redemption.customer_id = :customerId', { customerId })
      .groupBy('redemption.coupon_id')
      .getRawMany()) as Array<{ couponId: string; count: string }>;

    const totalByCoupon = new Map(
      totalRows.map((row) => [row.couponId, Number(row.count)]),
    );
    const customerByCoupon = new Map(
      customerRows.map((row) => [row.couponId, Number(row.count)]),
    );

    return coupons
      .filter((coupon) => {
        const totalUsed = totalByCoupon.get(coupon.id) ?? 0;
        const customerUsed = customerByCoupon.get(coupon.id) ?? 0;
        const totalExhausted =
          coupon.totalUsageLimit !== undefined &&
          totalUsed >= coupon.totalUsageLimit;
        const perCustomerExhausted =
          coupon.perCustomerLimit !== undefined &&
          customerUsed >= coupon.perCustomerLimit;
        return !totalExhausted && !perCustomerExhausted;
      })
      .map((coupon) => ({
        id: coupon.id,
        code: coupon.code,
        description: coupon.description ?? null,
        discountType: coupon.discountType,
        discountValue: coupon.discountValue,
        minOrderMinor: coupon.minOrderMinor,
        maxDiscountMinor: coupon.maxDiscountMinor ?? null,
        expiresAt: coupon.expiresAt ?? null,
      }));
  }

  private async resolveActiveRestaurantId(): Promise<string> {
    const restaurant = await this.dataSource.getRepository(Restaurant).findOne({
      where: { isActive: true },
      order: { createdAt: 'ASC' },
    });
    if (!restaurant) {
      throw new NotFoundException('Active restaurant is not configured');
    }
    return restaurant.id;
  }

  private computeDiscount(coupon: Coupon, subtotalMinor: number): number {
    if (subtotalMinor < Number(coupon.minOrderMinor ?? 0)) return 0;

    if (coupon.discountType === 'percentage') {
      const raw = Math.floor(
        (subtotalMinor * Number(coupon.discountValue)) / 100,
      );
      return coupon.maxDiscountMinor
        ? Math.min(raw, Number(coupon.maxDiscountMinor))
        : raw;
    }

    if (coupon.discountType === 'fixed_amount') {
      return Math.min(Number(coupon.discountValue), subtotalMinor);
    }

    return 0;
  }
}
