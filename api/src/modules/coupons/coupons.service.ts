import { Injectable } from '@nestjs/common';
import { requireEntity } from '../../common/utils/service-errors.util';
import { NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { StaffMember } from '../staff/entities/staff-member.entity';
import { CreateCouponDto } from './dto/create-coupon.dto';
import { UpdateCouponDto } from './dto/update-coupon.dto';
import { Coupon } from './entities/coupon.entity';
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
}
