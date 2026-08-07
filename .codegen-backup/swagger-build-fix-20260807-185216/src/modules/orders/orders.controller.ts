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
import { OrdersService } from './orders.service';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

import { ApiBearerAuth, ApiBody, ApiOperation, ApiParam, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';

@ApiTags('Orders')
@Controller('orders')
@UseGuards(JwtAuthGuard)
export class OrdersController {
  constructor(private readonly service: OrdersService) {}

  @Get('me')
  @ApiOperation({ summary: 'History' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  history(@CurrentUser() user: AuthenticatedUser) {
    return this.service.customerHistory(user.id);
  }

  @Get('me/:id')
  @ApiOperation({ summary: 'Detail' })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  detail(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.customerDetail(user.id, id);
  }

  @Post('me/:id/cancel')
  @ApiOperation({ summary: 'Cancel' })
  @ApiBody({ schema: { type: 'object', properties: { reason: { type: 'string' } } } })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
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
  @ApiQuery({ name: 'restaurantId', required: false, type: String })
  @ApiQuery({ name: 'status', required: false, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  adminList(
    @Query('restaurantId') restaurantId?: string,
    @Query('status') status?: string,
  ) {
    return this.service.listAdmin(restaurantId, status);
  }

  @Patch('admin/:id/status')
  @ApiOperation({ summary: 'Update Status' })
  @ApiBody({ type: UpdateOrderStatusDto })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  updateStatus(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    return this.service.updateStatus(id, dto, user.id);
  }
}
