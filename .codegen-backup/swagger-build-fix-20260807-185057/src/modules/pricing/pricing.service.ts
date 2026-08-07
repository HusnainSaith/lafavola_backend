import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { MenuItem } from '../menu/entities/menu-item.entity';
import { MenuItemSize } from '../menu/entities/menu-item-size.entity';
import { OptionChoice } from '../option-groups/entities/option-choice.entity';
import { OptionIncompatibility } from '../option-groups/entities/option-incompatibility.entity';
import { PriceBreakdown } from './interfaces/price-breakdown.interface';

export interface PriceSelection {
  menuItemId: string;
  sizeId?: string;
  optionChoiceIds?: string[];
  quantity?: number;
}

@Injectable()
export class PricingService {
  constructor(private readonly dataSource: DataSource) {}

  async calculate(selection: PriceSelection): Promise<PriceBreakdown> {
    const quantity = Math.max(1, selection.quantity ?? 1);
    const item = await this.dataSource.getRepository(MenuItem).findOne({
      where: { id: selection.menuItemId, isActive: true },
    });
    if (!item) throw new NotFoundException('Menu item not found');

    let basePriceMinor = 0;
    if (selection.sizeId) {
      const size = await this.dataSource.getRepository(MenuItemSize).findOne({
        where: { id: selection.sizeId, menuItemId: item.id, isActive: true },
      });
      if (!size) throw new BadRequestException('Invalid menu item size');
      basePriceMinor = size.basePriceMinor;
    }

    const choiceIds = [...new Set(selection.optionChoiceIds ?? [])];
    const choices = choiceIds.length
      ? await this.dataSource
          .getRepository(OptionChoice)
          .createQueryBuilder('choice')
          .where('choice.id IN (:...ids)', { ids: choiceIds })
          .andWhere('choice.is_active = true')
          .getMany()
      : [];

    if (choices.length !== choiceIds.length) {
      throw new BadRequestException(
        'One or more selected options are unavailable',
      );
    }

    if (choiceIds.length > 1) {
      const conflict = await this.dataSource
        .getRepository(OptionIncompatibility)
        .createQueryBuilder('conflict')
        .where(
          '(conflict.first_choice_id IN (:...ids) AND conflict.second_choice_id IN (:...ids))',
          { ids: choiceIds },
        )
        .getOne();
      if (conflict) {
        throw new BadRequestException(
          conflict.reason ?? 'Selected options are incompatible',
        );
      }
    }

    const optionsMinor = choices.reduce(
      (sum, choice) => sum + Number(choice.priceAdjustmentMinor ?? 0),
      0,
    );
    const unitPriceMinor = Math.max(0, basePriceMinor + optionsMinor);
    const lineTotalMinor = unitPriceMinor * quantity;

    return {
      basePriceMinor,
      optionAdjustmentsMinor: optionsMinor,
      unitPriceMinor,
      quantity,
      lineTotalMinor,
    } as PriceBreakdown;
  }
}
