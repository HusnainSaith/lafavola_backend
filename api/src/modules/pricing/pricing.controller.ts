import { Body, Controller, Post } from '@nestjs/common';
import { ApiBody, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

import { CalculatePriceDto } from './dto/calculate-price.dto';
import { PriceBreakdownDto } from './dto/price-breakdown.dto';
import { PricingService } from './pricing.service';

@ApiTags('Pricing')
@Controller('pricing')
export class PricingController {
  constructor(private readonly service: PricingService) {}

  @Post('calculate')
  @ApiOperation({
    summary: 'Calculate pizza/menu item price',
    description:
      'Calculates the authoritative backend price using the selected menu item, size, options, and quantity.',
  })
  @ApiBody({
    type: CalculatePriceDto,
  })
  @ApiResponse({
    status: 201,
    description: 'Price calculated successfully',
    type: PriceBreakdownDto,
  })
  @ApiResponse({
    status: 400,
    description:
      'Invalid menu item size, unavailable option, or incompatible options',
  })
  @ApiResponse({
    status: 404,
    description: 'Menu item not found',
  })
  calculate(@Body() body: CalculatePriceDto) {
    return this.service.calculate(body);
  }
}
