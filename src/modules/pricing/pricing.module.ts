import { Module } from '@nestjs/common';
import { PricingController } from './pricing.controller';
import { OrderTotalsService } from './order-totals.service';
import { PricingService } from './pricing.service';

@Module({
  controllers: [PricingController],
  providers: [PricingService, OrderTotalsService],
  exports: [PricingService, OrderTotalsService],
})
export class PricingModule {}
