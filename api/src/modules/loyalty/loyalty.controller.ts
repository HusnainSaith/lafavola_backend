import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RedeemLoyaltyPointsDto } from './dto/redeem-loyalty-points.dto';
import { LoyaltyService } from './loyalty.service';

import { ApiBody, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
@ApiTags('Customer App - Loyalty')
@Controller('loyalty')
@UseGuards(JwtAuthGuard)
export class LoyaltyController {
  constructor(private readonly service: LoyaltyService) {}

  @Get('balance')
  @ApiOperation({ summary: 'Balance' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  balance(@CurrentUser() user: AuthenticatedUser) {
    return this.service.balance(user.id);
  }

  @Get('history')
  @ApiOperation({ summary: 'History' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  history(@CurrentUser() user: AuthenticatedUser) {
    return this.service.history(user.id);
  }

  @Post('redeem')
  @ApiOperation({ summary: 'Redeem' })
  @ApiBody({ type: RedeemLoyaltyPointsDto })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  redeem(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RedeemLoyaltyPointsDto,
  ) {
    return this.service.redeem(user.id, dto);
  }
}
