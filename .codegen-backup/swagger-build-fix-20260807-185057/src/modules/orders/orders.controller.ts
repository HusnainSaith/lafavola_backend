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

@Controller('orders')
@UseGuards(JwtAuthGuard)
export class OrdersController {
  constructor(private readonly service: OrdersService) {}

  @Get('me')
  history(@CurrentUser() user: AuthenticatedUser) {
    return this.service.customerHistory(user.id);
  }

  @Get('me/:id')
  detail(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.customerDetail(user.id, id);
  }

  @Post('me/:id/cancel')
  cancel(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body('reason') reason?: string,
  ) {
    return this.service.cancelByCustomer(user.id, id, reason);
  }

  @Get('admin/list')
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  adminList(
    @Query('restaurantId') restaurantId?: string,
    @Query('status') status?: string,
  ) {
    return this.service.listAdmin(restaurantId, status);
  }

  @Patch('admin/:id/status')
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
