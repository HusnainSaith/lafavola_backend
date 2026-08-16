import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RoleEnum } from '../roles/role.enum';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { OrderHistoryQueryDto } from './dto/order-history-query.dto';
import { OrdersService } from './orders.service';
import { CheckoutService } from '../checkout/checkout.service';
import { CheckoutDto } from '../checkout/dto/checkout.dto';
import { CheckoutResultDto } from '../checkout/dto/checkout-result.dto';

import {
  ApiBody,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
@ApiTags('Customer App - Orders')
@Controller('orders')
@UseGuards(JwtAuthGuard)
export class OrdersController {
  constructor(
    private readonly service: OrdersService,
    private readonly checkoutService: CheckoutService,
  ) {}

  @Post('place')
  @ApiOperation({
    summary: 'Place Order',
    description:
      'Converts the authenticated customer cart into an order. The server reloads current prices and applies the admin delivery fee only when orderType is delivery. Pickup has no delivery fee.',
  })
  @ApiBody({ type: CheckoutDto })
  @ApiResponse({
    status: 201,
    description: 'Order created with authoritative totals',
    type: CheckoutResultDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid or empty cart' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 404, description: 'Delivery address not found' })
  @ApiResponse({ status: 409, description: 'Idempotency key conflict' })
  placeOrder(@CurrentUser() user: AuthenticatedUser, @Body() dto: CheckoutDto) {
    return this.checkoutService.checkout(user.id, dto);
  }

  @Get('me')
  @ApiOperation({ summary: 'History' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  history(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: OrderHistoryQueryDto,
  ) {
    return this.service.customerHistory(user.id, query);
  }

  @Get('me/:id')
  @ApiOperation({ summary: 'Detail' })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  detail(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.customerDetail(user.id, id);
  }

  @Get('me/:id/receipt')
  @ApiOperation({
    summary: 'Customer-readable order receipt with authoritative totals',
  })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Order receipt' })
  receipt(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.customerReceipt(user.id, id);
  }

  @Post('me/:id/reorder')
  @ApiOperation({
    summary: 'Revalidate an earlier order and add it to the active cart',
  })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 201, description: 'Current cart after reorder' })
  @ApiResponse({
    status: 422,
    description: 'One or more configurations are unavailable',
  })
  reorder(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.reorder(user.id, id);
  }

  @Post('me/:id/cancel')
  @ApiOperation({ summary: 'Cancel' })
  @ApiBody({
    schema: { type: 'object', properties: { reason: { type: 'string' } } },
  })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  cancel(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body('reason') reason?: string,
  ) {
    return this.service.cancelByCustomer(user.id, id, reason);
  }

  @Get('admin/list')
  @ApiOperation({ summary: 'Admin List' })
  @ApiQuery({ name: 'status', required: false, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  adminList(
    @CurrentUser() user: AuthenticatedUser,
    @Query('status') status?: string,
  ) {
    return this.service.listAdmin(user.id, status);
  }

  @Get('admin/:id')
  @ApiOperation({ summary: 'Admin Detail' })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  adminDetail(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.adminDetail(id, user.id);
  }

  @Patch('admin/:id/status')
  @ApiOperation({ summary: 'Update Status' })
  @ApiBody({ type: UpdateOrderStatusDto })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  updateStatus(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    return this.service.updateAdminStatus(id, dto, user.id);
  }
}
