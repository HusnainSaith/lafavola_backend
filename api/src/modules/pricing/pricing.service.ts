import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource, In } from 'typeorm';
import { MenuItemIngredient } from '../menu/entities/menu-item-ingredient.entity';
import { MenuItemSize } from '../menu/entities/menu-item-size.entity';
import { MenuItem } from '../menu/entities/menu-item.entity';
import { MenuItemOptionGroup } from '../option-groups/entities/menu-item-option-group.entity';
import { OptionChoice } from '../option-groups/entities/option-choice.entity';
import { OptionIncompatibility } from '../option-groups/entities/option-incompatibility.entity';
import { PizzaBuilderRule } from '../pizza-builder/entities/pizza-builder-rule.entity';
import {
  CalculatePriceDto,
  PricingOptionSelectionDto,
} from './dto/calculate-price.dto';
import { PriceBreakdown } from './interfaces/price-breakdown.interface';

@Injectable()
export class PricingService {
  constructor(private readonly dataSource: DataSource) {}

  async calculate(selection: CalculatePriceDto): Promise<PriceBreakdown> {
    const quantity = selection.quantity ?? 1;
    if (!Number.isSafeInteger(quantity) || quantity < 1)
      throw new BadRequestException('Invalid quantity');

    const now = new Date();
    const item = await this.dataSource.getRepository(MenuItem).findOne({
      where: { id: selection.menuItemId, isActive: true },
      relations: { restaurant: true },
    });
    if (
      !item ||
      !item.restaurant?.isActive ||
      item.archivedAt ||
      (item.availableFrom && item.availableFrom > now) ||
      (item.availableUntil && item.availableUntil <= now)
    ) {
      throw new NotFoundException('Menu item is unavailable');
    }

    const size = selection.sizeId
      ? await this.dataSource.getRepository(MenuItemSize).findOne({
          where: {
            id: selection.sizeId,
            menuItemId: item.id,
            isActive: true,
          },
        })
      : null;
    if (!size)
      throw new BadRequestException('A valid menu item size is required');

    const options: PricingOptionSelectionDto[] =
      selection.options ??
      (selection.optionChoiceIds ?? []).map((optionChoiceId) => ({
        optionChoiceId,
      }));
    const choiceIds = options
      .map((option) => option.optionChoiceId)
      .filter((id): id is string => Boolean(id));
    if (new Set(choiceIds).size !== choiceIds.length)
      throw new BadRequestException('Duplicate option choices are not allowed');

    const choices = choiceIds.length
      ? await this.dataSource.getRepository(OptionChoice).find({
          where: { id: In(choiceIds), isActive: true },
          relations: { optionGroup: true },
        })
      : [];
    if (
      choices.length !== choiceIds.length ||
      choices.some(
        (choice) =>
          !choice.optionGroup?.isActive ||
          choice.optionGroup.restaurantId !== item.restaurantId,
      )
    ) {
      throw new BadRequestException(
        'One or more selected options are unavailable',
      );
    }

    const mappings = await this.dataSource
      .getRepository(MenuItemOptionGroup)
      .find({
        where: { menuItemId: item.id },
        relations: { optionGroup: true },
      });
    const mappingByGroup = new Map(
      mappings.map((mapping) => [mapping.optionGroupId, mapping]),
    );
    for (const choice of choices) {
      if (!mappingByGroup.has(choice.optionGroupId))
        throw new BadRequestException(
          `Option ${choice.name} is not available for this menu item`,
        );
      const selected = options.find(
        (option) => option.optionChoiceId === choice.id,
      );
      if (
        (selected?.quantity ?? 1) !== 1 &&
        !choice.optionGroup.allowQuantity
      ) {
        throw new BadRequestException(
          `${choice.optionGroup.name} does not allow quantities`,
        );
      }
    }

    const selectedByGroup = new Map<string, number>();
    for (const choice of choices)
      selectedByGroup.set(
        choice.optionGroupId,
        (selectedByGroup.get(choice.optionGroupId) ?? 0) + 1,
      );
    for (const mapping of mappings) {
      if (!mapping.optionGroup.isActive) continue;
      const count = selectedByGroup.get(mapping.optionGroupId) ?? 0;
      const min =
        mapping.minSelectOverride ??
        mapping.optionGroup.minSelect ??
        (mapping.optionGroup.isRequired ? 1 : 0);
      const max = mapping.maxSelectOverride ?? mapping.optionGroup.maxSelect;
      if (count < min)
        throw new BadRequestException(
          `${mapping.optionGroup.name} requires at least ${min} selection(s)`,
        );
      if (max !== undefined && count > max)
        throw new BadRequestException(
          `${mapping.optionGroup.name} allows at most ${max} selection(s)`,
        );
    }

    await this.validateRemovals(item.id, options);
    await this.validateIncompatibilities(choiceIds);

    const rule = await this.dataSource
      .getRepository(PizzaBuilderRule)
      .findOne({ where: { menuItemId: item.id, isActive: true } });
    if (item.itemType === 'build_your_own')
      this.validateBuilderRule(rule, choices);

    let optionAdjustmentsMinor = choices.reduce((sum, choice) => {
      const selected = options.find(
        (option) => option.optionChoiceId === choice.id,
      );
      return (
        sum + Number(choice.priceAdjustmentMinor) * (selected?.quantity ?? 1)
      );
    }, 0);
    if (rule?.toppingsGroupId && rule.freeToppingCount > 0) {
      const toppingPrices = choices
        .filter((choice) => choice.optionGroupId === rule.toppingsGroupId)
        .map((choice) => Math.max(0, Number(choice.priceAdjustmentMinor)))
        .sort((a, b) => a - b);
      optionAdjustmentsMinor -= toppingPrices
        .slice(0, rule.freeToppingCount)
        .reduce((sum, price) => sum + price, 0);
    }
    const basePriceMinor = Number(size.basePriceMinor);
    const unitPriceMinor = basePriceMinor + optionAdjustmentsMinor;
    if (!Number.isSafeInteger(unitPriceMinor) || unitPriceMinor < 0)
      throw new BadRequestException('Calculated unit price is invalid');
    const lineTotalMinor = unitPriceMinor * quantity;
    if (!Number.isSafeInteger(lineTotalMinor))
      throw new BadRequestException('Calculated price exceeds supported range');

    return {
      currency: 'EUR',
      basePriceMinor,
      optionAdjustmentsMinor,
      unitPriceMinor,
      quantity,
      lineTotalMinor,
      subtotalMinor: basePriceMinor * quantity,
      optionChargesMinor: optionAdjustmentsMinor * quantity,
      discountMinor: 0,
      loyaltyDiscountMinor: 0,
      deliveryFeeMinor: 0,
      taxMinor: 0,
      grandTotalMinor: Math.max(0, lineTotalMinor),
      appliedPromotionIds: [],
    };
  }

  private async validateRemovals(
    menuItemId: string,
    options: PricingOptionSelectionDto[],
  ) {
    const removals = options.filter((option) => option.action === 'remove');
    if (!removals.length) return;
    if (
      removals.some((option) => !option.ingredientId || option.optionChoiceId)
    )
      throw new BadRequestException('Invalid ingredient removal');
    const ids = removals.map((option) => option.ingredientId as string);
    if (new Set(ids).size !== ids.length)
      throw new BadRequestException(
        'Duplicate ingredient removals are not allowed',
      );
    const allowed = await this.dataSource
      .getRepository(MenuItemIngredient)
      .count({
        where: {
          menuItemId,
          ingredientId: In(ids),
          isDefault: true,
          isRemovable: true,
        },
      });
    if (allowed !== ids.length)
      throw new BadRequestException(
        'One or more ingredients cannot be removed',
      );
  }

  private async validateIncompatibilities(choiceIds: string[]) {
    if (choiceIds.length < 2) return;
    const conflict = await this.dataSource
      .getRepository(OptionIncompatibility)
      .createQueryBuilder('conflict')
      .where(
        'conflict.first_choice_id IN (:...ids) AND conflict.second_choice_id IN (:...ids)',
        { ids: choiceIds },
      )
      .getOne();
    if (conflict)
      throw new BadRequestException(
        conflict.reason ?? 'Selected options are incompatible',
      );
  }

  private validateBuilderRule(
    rule: PizzaBuilderRule | null,
    choices: OptionChoice[],
  ) {
    if (!rule)
      throw new BadRequestException(
        'Pizza builder configuration is unavailable',
      );
    const groupIds = new Set(choices.map((choice) => choice.optionGroupId));
    for (const [label, id] of [
      ['dough', rule.doughGroupId],
      ['sauce', rule.sauceGroupId],
      ['cheese', rule.cheeseGroupId],
    ] as const) {
      if (!id || !groupIds.has(id))
        throw new BadRequestException(`A ${label} selection is required`);
    }
    const toppingCount = rule.toppingsGroupId
      ? choices.filter(
          (choice) => choice.optionGroupId === rule.toppingsGroupId,
        ).length
      : 0;
    if (
      rule.maxTotalToppings !== undefined &&
      toppingCount > rule.maxTotalToppings
    )
      throw new BadRequestException(
        `At most ${rule.maxTotalToppings} toppings may be selected`,
      );
  }
}
