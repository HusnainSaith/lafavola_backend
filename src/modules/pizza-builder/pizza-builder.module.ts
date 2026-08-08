import { Module } from '@nestjs/common';
import { PricingModule } from '../pricing/pricing.module';
import { PizzaBuilderController } from './pizza-builder.controller';
import { PizzaBuilderService } from './pizza-builder.service';
import { PizzaBuilderRuleRepository } from './repositories/pizza-builder-rule.repository';

@Module({
  imports: [PricingModule],
  controllers: [PizzaBuilderController],
  providers: [PizzaBuilderService, PizzaBuilderRuleRepository],
  exports: [PizzaBuilderService],
})
export class PizzaBuilderModule {}
