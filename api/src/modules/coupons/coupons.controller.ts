import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RoleEnum } from '../roles/role.enum';
import { Public } from '../../common/decorators/public.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CouponsService } from './coupons.service';
import { CreateCouponDto } from './dto/create-coupon.dto';
import { UpdateCouponDto } from './dto/update-coupon.dto';
import { ValidateCouponDto } from './dto/validate-coupon.dto';

import {
  ApiBody,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
@ApiTags('Coupons')
@Controller('coupons')
export class CouponsController {
  constructor(private readonly service: CouponsService) {}

  @Get()
  @ApiOperation({ summary: 'Find All' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  findAll() {
    return this.service.findAll();
  }

  @Post('validate')
  @Public()
  @ApiOperation({
    summary: 'Validate a coupon code and preview its discount',
    description:
      'Customer-facing coupon validation. Accepts a code (and optional cart subtotal/restaurant) and returns whether the code is valid and the discount it will apply, mirroring checkout rules.',
  })
  @ApiBody({ type: ValidateCouponDto })
  @ApiResponse({ status: 201, description: 'Coupon validated successfully' })
  @ApiResponse({
    status: 400,
    description: 'Coupon is invalid, expired or out of its active window',
  })
  validate(@Body() dto: ValidateCouponDto) {
    return this.service.validate(dto);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({
    summary: 'List coupons available to the authenticated customer',
    description:
      'Customer coupon inbox. Returns coupons that are currently active, in their time window and not exhausted by total/per-customer usage limits.',
  })
  @ApiResponse({ status: 200, description: 'List of redeemable coupons' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  listForCustomer(@CurrentUser() user: AuthenticatedUser) {
    return this.service.listForCustomer(user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Find One' })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  findOne(@Param('id') id: string) {
    return this.service.findById(id);
  }

  @Post()
  @ApiOperation({ summary: 'Create' })
  @ApiBody({ type: CreateCouponDto })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateCouponDto) {
    return this.service.create(dto, user.id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update' })
  @ApiBody({ type: UpdateCouponDto })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateCouponDto,
  ) {
    return this.service.update(id, dto, user.id);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove' })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  async remove(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    await this.service.remove(id, user.id);
    return { success: true };
  }
}
