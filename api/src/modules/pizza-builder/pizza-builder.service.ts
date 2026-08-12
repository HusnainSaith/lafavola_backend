import { Injectable, NotFoundException } from '@nestjs/common';
import { DataSource, In } from 'typeorm';
import { MenuItem } from '../menu/entities/menu-item.entity';
import { MenuItemSize } from '../menu/entities/menu-item-size.entity';
import { OptionGroup } from '../option-groups/entities/option-group.entity';
import { OptionChoice } from '../option-groups/entities/option-choice.entity';
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

  async getConfiguration(menuItemId: string) {
    const rule = await this.getRule(menuItemId);
    const item = await this.dataSource.getRepository(MenuItem).findOne({
      where: { id: menuItemId, isActive: true },
    });
    if (!item) throw new NotFoundException('Menu item not found');

    const sizes = await this.dataSource.getRepository(MenuItemSize).find({
      where: { menuItemId, isActive: true },
      order: { displayOrder: 'ASC', createdAt: 'ASC' },
    });
    const groupDefinitions = [
      ['dough', rule.doughGroupId],
      ['sauce', rule.sauceGroupId],
      ['cheese', rule.cheeseGroupId],
      ['toppings', rule.toppingsGroupId],
    ] as const;
    const groupIds = groupDefinitions
      .map(([, id]) => id)
      .filter((id): id is string => Boolean(id));
    const groups = groupIds.length
      ? await this.dataSource.getRepository(OptionGroup).find({
          where: { id: In(groupIds), isActive: true },
        })
      : [];
    const choices = groupIds.length
      ? await this.dataSource.getRepository(OptionChoice).find({
          where: { optionGroupId: In(groupIds), isActive: true },
          order: { displayOrder: 'ASC', createdAt: 'ASC' },
        })
      : [];
    const groupsById = new Map(groups.map((group) => [group.id, group]));

    return {
      menuItem: {
        id: item.id,
        name: item.name,
        description: item.description ?? null,
      },
      sizes: sizes.map((size) => ({
        id: size.id,
        code: size.sizeCode,
        name: size.displayName,
        basePriceMinor: size.basePriceMinor,
        calories: size.calories ?? null,
      })),
      groups: groupDefinitions
        .filter(([, id]) => id && groupsById.has(id))
        .map(([type, id]) => {
          const group = groupsById.get(id!)!;
          return {
            type,
            id: group.id,
            name: group.name,
            required: group.isRequired || group.minSelect > 0,
            minSelections: group.minSelect,
            maxSelections:
              type === 'toppings'
                ? (rule.maxTotalToppings ?? group.maxSelect ?? null)
                : (group.maxSelect ?? 1),
            choices: choices
              .filter((choice) => choice.optionGroupId === group.id)
              .map((choice) => ({
                id: choice.id,
                name: choice.name,
                priceAdjustmentMinor: choice.priceAdjustmentMinor,
                caloriesAdjustment: choice.caloriesAdjustment,
                selectedByDefault: choice.isDefault,
              })),
          };
        }),
      rules: {
        freeToppingCount: rule.freeToppingCount,
        maxTotalToppings: rule.maxTotalToppings ?? null,
      },
    };
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

    const selectedChoices = optionChoiceIds.length
      ? await this.dataSource.getRepository(OptionChoice).find({
          where: { id: In(optionChoiceIds) },
        })
      : [];
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
      selectionSummary: selectedChoices.map((choice) => ({
        type:
          choice.optionGroupId === rule.doughGroupId
            ? 'dough'
            : choice.optionGroupId === rule.sauceGroupId
              ? 'sauce'
              : choice.optionGroupId === rule.cheeseGroupId
                ? 'cheese'
                : 'topping',
        name: choice.name,
        priceAdjustmentMinor: choice.priceAdjustmentMinor,
      })),
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
