import { Injectable } from '@nestjs/common';
import { PromotionRepository } from './repositories/promotion.repository';
import { Promotion } from './entities/promotion.entity';
import { CreatePromotionDto } from './dto/create-promotion.dto';
import { UpdatePromotionDto } from './dto/update-promotion.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class PromotionsService {
  constructor(private readonly repository: PromotionRepository) {}

  findAll(): Promise<Promotion[]> {
    return this.repository.findMany({
      order: { createdAt: 'DESC' },
    });
  }

  async findById(id: string): Promise<Promotion> {
    return requireEntity(
      await this.repository.findById(id),
      'Promotion record not found',
    );
  }

  create(dto: CreatePromotionDto): Promise<Promotion> {
    return this.repository.save(
      this.repository.create({
        restaurantId: dto.restaurantId,
        name: dto.name,
        description: dto.description,
        promotionType: dto.promotionType,
        discountValue: dto.discountValue ?? 0,
        minOrderMinor: dto.minOrderMinor ?? 0,
        maxDiscountMinor: dto.maxDiscountMinor,
        startsAt: new Date(dto.startsAt),
        endsAt: dto.endsAt ? new Date(dto.endsAt) : undefined,
        totalUsageLimit: dto.totalUsageLimit,
        perCustomerLimit: dto.perCustomerLimit,
        priority: dto.priority ?? 0,
        stackingGroup: dto.stackingGroup,
        isAutomatic: dto.isAutomatic ?? true,
        isActive: dto.isActive ?? true,
        conditions: dto.conditions ?? {},
        actions: dto.actions ?? {},
      }),
    );
  }

  async update(
    id: string,
    dto: UpdatePromotionDto,
  ): Promise<Promotion> {
    const entity = await this.findById(id);

    Object.assign(entity, {
      ...dto,
      startsAt: dto.startsAt
        ? new Date(dto.startsAt)
        : entity.startsAt,
      endsAt: dto.endsAt
        ? new Date(dto.endsAt)
        : entity.endsAt,
    });

    return this.repository.save(entity);
  }

  async remove(id: string): Promise<void> {
    const entity = await this.findById(id);
    entity.isActive = false;
    await this.repository.save(entity);
  }
}
