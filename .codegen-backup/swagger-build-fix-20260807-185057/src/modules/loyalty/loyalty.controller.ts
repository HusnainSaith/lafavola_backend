import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { LoyaltyService } from './loyalty.service';
import { RedeemLoyaltyPointsDto } from './dto/redeem-loyalty-points.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';

@Controller('loyalty')
@UseGuards(JwtAuthGuard)
export class LoyaltyController {
  constructor(private readonly service: LoyaltyService) {}

  @Get('balance')
  balance(@CurrentUser() user: AuthenticatedUser) {
    return this.service.balance(user.id);
  }

  @Get('history')
  history(@CurrentUser() user: AuthenticatedUser) {
    return this.service.history(user.id);
  }

  @Post('redeem')
  redeem(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RedeemLoyaltyPointsDto,
  ) {
    return this.service.redeem(user.id, dto);
  }
}
