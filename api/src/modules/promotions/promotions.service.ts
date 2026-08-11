import { Injectable } from '@nestjs/common';
import { DataSource, EntityManager, In } from 'typeorm';
import { NotFoundException } from '@nestjs/common';
import { StaffMember } from '../staff/entities/staff-member.entity';
import { requireEntity } from '../../common/utils/service-errors.util';
import { CreatePromotionDto } from './dto/create-promotion.dto';
import { UpdatePromotionDto } from './dto/update-promotion.dto';
import { PromotionItem } from './entities/promotion-item.entity';
import { PromotionRedemption } from './entities/promotion-redemption.entity';
import { Promotion } from './entities/promotion.entity';
import { PromotionRepository } from './repositories/promotion.repository';

export interface PromotionLine {
  menuItemId: string;
  categoryId?: string;
  lineTotalMinor: number;
}

export interface AppliedPromotion {
  id: string;
  name: string;
  type: string;
  stackingGroup?: string;
  priority: number;
  discountMinor: number;
  deliveryDiscountMinor: number;
}

export interface PromotionEvaluation {
  promotionDiscountMinor: number;
  deliveryDiscountMinor: number;
  appliedPromotions: AppliedPromotion[];
  unsupportedPromotions: Array<{ id: string; type: string; reason: string }>;
}

@Injectable()
export class PromotionsService {
  constructor(
    private readonly repository: PromotionRepository,
    private readonly dataSource: DataSource,
  ) {}

  findAll(): Promise<Promotion[]> {
    return this.repository.findMany({ order: { createdAt: 'DESC' } });
  }

  async findById(id: string): Promise<Promotion> {
    return requireEntity(
      await this.repository.findById(id),
      'Promotion record not found',
    );
  }

  async evaluateAutomatic(
    manager: EntityManager,
    input: {
      restaurantId: string;
      customerId: string;
      subtotalMinor: number;
      deliveryFeeMinor: number;
      lines: PromotionLine[];
      hasCoupon: boolean;
      now?: Date;
      lock?: boolean;
    },
  ): Promise<PromotionEvaluation> {
    const now = input.now ?? new Date();
    let query = manager
      .getRepository(Promotion)
      .createQueryBuilder('promotion')
      .where('promotion.restaurant_id = :restaurantId', {
        restaurantId: input.restaurantId,
      })
      .andWhere('promotion.is_active = true')
      .andWhere('promotion.is_automatic = true')
      .andWhere('promotion.starts_at <= :now', { now })
      .andWhere('(promotion.ends_at IS NULL OR promotion.ends_at > :now)', {
        now,
      })
      .orderBy('promotion.priority', 'DESC')
      .addOrderBy('promotion.id', 'ASC');
    if (input.lock) query = query.setLock('pessimistic_write');
    const promotions = await query.getMany();
    if (!promotions.length) return this.emptyEvaluation();

    const items = await manager.getRepository(PromotionItem).find({
      where: { promotionId: In(promotions.map(({ id }) => id)) },
    });
    const redemptionRows = await manager
      .getRepository(PromotionRedemption)
      .createQueryBuilder('redemption')
      .select('redemption.promotion_id', 'promotionId')
      .addSelect('COUNT(*)', 'totalUses')
      .addSelect(
        'COUNT(*) FILTER (WHERE redemption.customer_id = :customerId)',
        'customerUses',
      )
      .where('redemption.promotion_id IN (:...ids)', {
        ids: promotions.map(({ id }) => id),
      })
      .setParameter('customerId', input.customerId)
      .groupBy('redemption.promotion_id')
      .getRawMany<{
        promotionId: string;
        totalUses: string;
        customerUses: string;
      }>();
    const usage = new Map(redemptionRows.map((row) => [row.promotionId, row]));
    const applied: AppliedPromotion[] = [];
    const unsupported: PromotionEvaluation['unsupportedPromotions'] = [];
    const claimedGroups = new Set<string>();

    for (const promotion of promotions) {
      if (!this.isDayEligible(promotion, now)) continue;
      if (input.subtotalMinor < Number(promotion.minOrderMinor)) continue;
      const counts = usage.get(promotion.id);
      if (
        promotion.totalUsageLimit != null &&
        Number(counts?.totalUses ?? 0) >= promotion.totalUsageLimit
      )
        continue;
      if (
        promotion.perCustomerLimit != null &&
        Number(counts?.customerUses ?? 0) >= promotion.perCustomerLimit
      )
        continue;
      if (!this.isLineEligible(promotion.id, items, input.lines)) continue;
      if (input.hasCoupon && promotion.conditions.couponCompatible !== true)
        continue;

      const group = promotion.stackingGroup ?? `promotion:${promotion.id}`;
      if (claimedGroups.has(group)) continue;
      const incompatible = this.stringArray(
        promotion.conditions.incompatibleStackingGroups,
      );
      if (
        applied.some((entry) =>
          incompatible.includes(entry.stackingGroup ?? ''),
        )
      )
        continue;
      if (
        applied.some((entry) => {
          const other = promotions.find(({ id }) => id === entry.id);
          return this.stringArray(
            other?.conditions.incompatibleStackingGroups,
          ).includes(group);
        })
      )
        continue;

      const calculated = this.calculatePromotion(promotion, input);
      if (!calculated) {
        unsupported.push({
          id: promotion.id,
          type: promotion.promotionType,
          reason: 'UNSUPPORTED_OR_INCOMPLETE_CONFIGURATION',
        });
        continue;
      }
      if (calculated.discountMinor + calculated.deliveryDiscountMinor <= 0)
        continue;
      applied.push({
        id: promotion.id,
        name: promotion.name,
        type: promotion.promotionType,
        stackingGroup: promotion.stackingGroup,
        priority: promotion.priority,
        ...calculated,
      });
      claimedGroups.add(group);
    }

    return {
      promotionDiscountMinor: Math.min(
        input.subtotalMinor,
        applied.reduce((sum, item) => sum + item.discountMinor, 0),
      ),
      deliveryDiscountMinor: Math.min(
        input.deliveryFeeMinor,
        applied.reduce((sum, item) => sum + item.deliveryDiscountMinor, 0),
      ),
      appliedPromotions: applied,
      unsupportedPromotions: unsupported,
    };
  }

  private emptyEvaluation(): PromotionEvaluation {
    return {
      promotionDiscountMinor: 0,
      deliveryDiscountMinor: 0,
      appliedPromotions: [],
      unsupportedPromotions: [],
    };
  }

  private isDayEligible(promotion: Promotion, now: Date): boolean {
    return (
      !promotion.daysOfWeek.length ||
      promotion.daysOfWeek.includes(now.getUTCDay())
    );
  }

  private isLineEligible(
    promotionId: string,
    allItems: PromotionItem[],
    lines: PromotionLine[],
  ): boolean {
    const items = allItems.filter((item) => item.promotionId === promotionId);
    const matches = (item: PromotionItem, line: PromotionLine) =>
      item.menuItemId === line.menuItemId ||
      (item.categoryId != null && item.categoryId === line.categoryId);
    if (
      items.some(
        (item) =>
          item.eligibilityType === 'excluded' &&
          lines.some((line) => matches(item, line)),
      )
    )
      return false;
    const eligible = items.filter(
      (item) => item.eligibilityType === 'eligible',
    );
    return (
      !eligible.length ||
      eligible.some((item) => lines.some((line) => matches(item, line)))
    );
  }

  private calculatePromotion(
    promotion: Promotion,
    input: { subtotalMinor: number; deliveryFeeMinor: number },
  ): { discountMinor: number; deliveryDiscountMinor: number } | null {
    if (promotion.promotionType === 'free_delivery') {
      return {
        discountMinor: 0,
        deliveryDiscountMinor: input.deliveryFeeMinor,
      };
    }
    let discountMinor: number;
    if (promotion.promotionType === 'percentage') {
      discountMinor = Math.floor(
        (input.subtotalMinor * promotion.discountValue) / 100,
      );
    } else if (promotion.promotionType === 'fixed_amount') {
      discountMinor = promotion.discountValue;
    } else {
      return null;
    }
    if (promotion.maxDiscountMinor != null)
      discountMinor = Math.min(discountMinor, promotion.maxDiscountMinor);
    return {
      discountMinor: Math.min(input.subtotalMinor, discountMinor),
      deliveryDiscountMinor: 0,
    };
  }

  private stringArray(value: unknown): string[] {
    return Array.isArray(value)
      ? value.filter((item): item is string => typeof item === 'string')
      : [];
  }

  async create(
    dto: CreatePromotionDto,
    actorUserId: string,
  ): Promise<Promotion> {
    const restaurantId = await this.restaurantForActor(actorUserId);
    if (dto.restaurantId !== restaurantId) {
      throw new NotFoundException('Restaurant not found');
    }
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
    actorUserId: string,
  ): Promise<Promotion> {
    const restaurantId = await this.restaurantForActor(actorUserId);
    const entity = await this.repository.findOne({
      where: { id, restaurantId },
    });
    if (!entity) throw new NotFoundException('Promotion record not found');
    if (dto.restaurantId && dto.restaurantId !== restaurantId) {
      throw new NotFoundException('Restaurant not found');
    }
    Object.assign(entity, {
      ...dto,
      startsAt: dto.startsAt ? new Date(dto.startsAt) : entity.startsAt,
      endsAt: dto.endsAt ? new Date(dto.endsAt) : entity.endsAt,
    });
    return this.repository.save(entity);
  }

  async remove(id: string, actorUserId: string): Promise<void> {
    const restaurantId = await this.restaurantForActor(actorUserId);
    const entity = await this.repository.findOne({
      where: { id, restaurantId },
    });
    if (!entity) throw new NotFoundException('Promotion record not found');
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
