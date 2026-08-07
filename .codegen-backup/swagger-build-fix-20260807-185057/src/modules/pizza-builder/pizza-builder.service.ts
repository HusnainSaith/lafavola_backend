import { Injectable, NotFoundException } from '@nestjs/common';
import { PizzaBuilderRuleRepository } from './repositories/pizza-builder-rule.repository';
import { BuildPizzaDto } from './dto/build-pizza.dto';
import { PricingService } from '../pricing/pricing.service';

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
    if (!rule)
      throw new NotFoundException('Pizza builder configuration not found');
    return rule;
  }

  async build(dto: BuildPizzaDto) {
    const rule = await this.getRule(dto.menuItemId);
    const price = await this.pricing.calculate({
      menuItemId: dto.menuItemId,
      sizeId: dto.sizeId,
      optionChoiceIds: dto.optionChoiceIds,
      quantity: dto.quantity ?? 1,
    });

    return {
      menuItemId: dto.menuItemId,
      ruleId: rule.id,
      configuration: {
        sizeId: dto.sizeId,
        optionChoiceIds: dto.optionChoiceIds ?? [],
      },
      price,
    };
  }
}
