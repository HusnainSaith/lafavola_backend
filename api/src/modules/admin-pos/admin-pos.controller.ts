import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CollectPaymentDto } from '../payments/dto/collect-payment.dto';
import { RoleEnum } from '../roles/role.enum';
import { AdminPosService } from './admin-pos.service';
import { CreatePosOrderDto } from './dto/create-pos-order.dto';
import { ListPosReceiptsDto } from './dto/list-pos-receipts.dto';

@ApiTags('Admin POS')
@ApiBearerAuth('JWT-auth')
@Controller('admin/pos')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(RoleEnum.ADMIN)
export class AdminPosController {
  constructor(private readonly service: AdminPosService) {}

  @Get('catalog')
  @ApiOperation({ summary: 'Get the restaurant-scoped POS catalogue' })
  @ApiResponse({ status: 200, description: 'POS catalogue' })
  catalog(@CurrentUser() user: AuthenticatedUser) {
    return this.service.catalog(user.id);
  }

  @Post('orders')
  @ApiOperation({ summary: 'Create an idempotent dine-in or takeaway order' })
  @ApiBody({ type: CreatePosOrderDto })
  @ApiResponse({ status: 201, description: 'Walk-in order created' })
  createOrder(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreatePosOrderDto,
  ) {
    return this.service.createOrder(user.id, dto);
  }

  @Post('orders/:id/collect')
  @ApiOperation({ summary: 'Collect a walk-in cash or terminal payment' })
  @ApiParam({ name: 'id', type: String })
  @ApiBody({ type: CollectPaymentDto })
  @ApiResponse({
    status: 201,
    description: 'Payment collected and receipt issued',
  })
  collect(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: CollectPaymentDto,
  ) {
    return this.service.collect(user.id, id, dto);
  }

  @Get('orders/:id/receipt')
  @ApiOperation({
    summary: 'Get a printable order ticket or paid receipt',
  })
  @ApiParam({ name: 'id', type: String })
  @ApiResponse({ status: 200, description: 'Printable receipt model' })
  receipt(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.receipt(user.id, id);
  }

  @Get('receipts')
  @ApiOperation({ summary: 'List all paid restaurant receipts for reprinting' })
  @ApiResponse({ status: 200, description: 'Paginated receipt list' })
  receipts(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: ListPosReceiptsDto,
  ) {
    return this.service.listReceipts(user.id, query);
  }
}
