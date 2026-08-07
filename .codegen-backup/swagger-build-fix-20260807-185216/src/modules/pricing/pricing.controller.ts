import { Body, Controller, Post } from '@nestjs/common';
import { PricingService, PriceSelection } from './pricing.service';

import { ApiBearerAuth, ApiBody, ApiOperation, ApiParam, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';

@ApiTags('Pricing')
@Controller('pricing')
export class PricingController {
  constructor(private readonly service: PricingService) {}

  @Post('calculate')
  @ApiOperation({ summary: 'Calculate' })
  @ApiBody({ type: PriceSelection })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  calculate(@Body() body: PriceSelection) {
    return this.service.calculate(body);
  }
}
