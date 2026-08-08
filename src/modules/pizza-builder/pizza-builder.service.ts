import { Injectable, NotFoundException } from '@nestjs/common';
import { PricingService } from '../pricing/pricing.service';
import { BuildPizzaDto } from './dto/build-pizza.dto';
import { PizzaBuilderRuleRepository } from './repositories/pizza-builder-rule.repository';

@Injectable()
export class PizzaBuilderService {
  constructor(
    private readonly rules: PizzaBuilderRuleRepository,
    private readonly pricing: PricingService,
  ) {}

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
}
