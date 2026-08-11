import { Injectable, NotFoundException } from '@nestjs/common';
import { DataSource, In } from 'typeorm';
import { MenuItem } from '../menu/entities/menu-item.entity';
import { OptionGroup } from '../option-groups/entities/option-group.entity';
import { PricingService } from '../pricing/pricing.service';
import { StaffMember } from '../staff/entities/staff-member.entity';
import { BuildPizzaDto } from './dto/build-pizza.dto';
import {
  CreatePizzaBuilderRuleDto,
  UpdatePizzaBuilderRuleDto,
} from './dto/manage-pizza-builder-rule.dto';
import { PizzaBuilderRuleRepository } from './repositories/pizza-builder-rule.repository';

@Injectable()
export class PizzaBuilderService {
  constructor(
    private readonly rules: PizzaBuilderRuleRepository,
    private readonly pricing: PricingService,
    private readonly dataSource: DataSource,
  ) {}

  async listAdmin(actorUserId: string) {
    const restaurantId = await this.restaurantForActor(actorUserId);
    return this.rules.findMany({
      where: { restaurantId },
      order: { createdAt: 'DESC' },
    });
  }

  async createAdmin(actorUserId: string, dto: CreatePizzaBuilderRuleDto) {
    const restaurantId = await this.restaurantForActor(actorUserId);
    await this.validateReferences(restaurantId, dto);
    return this.rules.save(
      this.rules.create({
        ...dto,
        restaurantId,
        freeToppingCount: dto.freeToppingCount ?? 0,
        ruleConfig: {},
        isActive: dto.isActive ?? true,
      }),
    );
  }

  async updateAdmin(
    actorUserId: string,
    id: string,
    dto: UpdatePizzaBuilderRuleDto,
  ) {
    const restaurantId = await this.restaurantForActor(actorUserId);
    const rule = await this.rules.findOne({ where: { id, restaurantId } });
    if (!rule) throw new NotFoundException('Pizza builder rule not found');
    await this.validateReferences(restaurantId, dto, rule.menuItemId);
    Object.assign(rule, dto);
    return this.rules.save(rule);
  }

  async deactivateAdmin(actorUserId: string, id: string) {
    const restaurantId = await this.restaurantForActor(actorUserId);
    const rule = await this.rules.findOne({ where: { id, restaurantId } });
    if (!rule) throw new NotFoundException('Pizza builder rule not found');
    rule.isActive = false;
    return this.rules.save(rule);
  }

  async getRule(menuItemId: string) {
    const rule = await this.rules.findOne({
      where: { menuItemId, isActive: true },
    });

    if (!rule) {
      throw new NotFoundException('Pizza builder configuration not found');
    }

    return rule;
  }

  async build(dto: BuildPizzaDto) {
    const rule = await this.getRule(dto.menuItemId);

    const optionChoiceIds = [
      dto.doughChoiceId,
      dto.sauceChoiceId,
      dto.cheeseChoiceId,
      ...(dto.toppingChoiceIds ?? []),
    ].filter((id): id is string => Boolean(id));

    const price = await this.pricing.calculate({
      menuItemId: dto.menuItemId,
      sizeId: dto.menuItemSizeId,
      optionChoiceIds,
      quantity: 1,
    });

    return {
      menuItemId: dto.menuItemId,
      ruleId: rule.id,
      configuration: {
        menuItemSizeId: dto.menuItemSizeId,
        doughChoiceId: dto.doughChoiceId,
        sauceChoiceId: dto.sauceChoiceId,
        cheeseChoiceId: dto.cheeseChoiceId,
        toppingChoiceIds: dto.toppingChoiceIds ?? [],
      },
      price,
    };
  }

  private async restaurantForActor(actorUserId: string) {
    const staff = await this.dataSource.getRepository(StaffMember).findOne({
      where: { userId: actorUserId, isActive: true },
      select: { restaurantId: true },
    });
    if (!staff) throw new NotFoundException('Staff member not found');
    return staff.restaurantId;
  }

  private async validateReferences(
    restaurantId: string,
    dto: UpdatePizzaBuilderRuleDto,
    existingMenuItemId?: string,
  ) {
    const menuItemId = dto.menuItemId ?? existingMenuItemId;
    if (menuItemId) {
      const item = await this.dataSource.getRepository(MenuItem).findOne({
        where: { id: menuItemId, restaurantId },
      });
      if (!item) throw new NotFoundException('Menu item not found');
    }
    const groupIds = [
      dto.sizeGroupId,
      dto.doughGroupId,
      dto.sauceGroupId,
      dto.cheeseGroupId,
      dto.toppingsGroupId,
    ].filter((id): id is string => Boolean(id));
    if (!groupIds.length) return;
    const count = await this.dataSource.getRepository(OptionGroup).count({
      where: { id: In(groupIds), restaurantId, isActive: true },
    });
    if (count !== new Set(groupIds).size) {
      throw new NotFoundException('Option group not found');
    }
  }
}
