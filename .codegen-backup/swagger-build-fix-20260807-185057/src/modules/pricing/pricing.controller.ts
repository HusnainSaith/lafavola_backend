import { Body, Controller, Post } from '@nestjs/common';
import { PricingService, PriceSelection } from './pricing.service';

@Controller('pricing')
export class PricingController {
  constructor(private readonly service: PricingService) {}

  @Post('calculate')
  calculate(@Body() body: PriceSelection) {
    return this.service.calculate(body);
  }
}
