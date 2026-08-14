import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CheckoutService } from './checkout.service';
import { CheckoutDto } from './dto/checkout.dto';
import { CheckoutResultDto } from './dto/checkout-result.dto';

import { ApiBody, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
@ApiTags('Customer App - Checkout')
@Controller('checkout')
@UseGuards(JwtAuthGuard)
export class CheckoutController {
  constructor(private readonly service: CheckoutService) {}

  @Post()
  @ApiOperation({ summary: 'Checkout' })
  @ApiBody({ type: CheckoutDto })
  @ApiResponse({
    status: 201,
    description: 'Successful response',
    type: CheckoutResultDto,
  })
  @ApiResponse({ status: 409, description: 'Idempotency key request conflict' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  checkout(@CurrentUser() user: AuthenticatedUser, @Body() dto: CheckoutDto) {
    return this.service.checkout(user.id, dto);
  }
}
