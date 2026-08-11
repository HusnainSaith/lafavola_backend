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
import { AdminListQueryDto } from '../../common/dto/admin-list-query.dto';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RoleEnum } from '../roles/role.enum';
import { CreateRefundDto } from './dto/create-refund.dto';
import { RefundsService } from './refunds.service';

import {
  ApiBody,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
@ApiTags('Refunds')
@Controller('refunds')
@UseGuards(JwtAuthGuard)
export class RefundsController {
  constructor(private readonly service: RefundsService) {}

  @Get('admin')
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  @ApiOperation({ summary: 'List refunds for the active staff restaurant' })
  @ApiResponse({ status: 200, description: 'Paginated refund queue' })
  adminList(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: AdminListQueryDto,
  ) {
    return this.service.listAdmin(user.id, query);
  }

  @Post()
  @ApiOperation({ summary: 'Create' })
  @ApiBody({ type: CreateRefundDto })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateRefundDto) {
    return this.service.create(user.id, dto, isAdmin(user));
  }

  @Get('orders/:orderId')
  @ApiOperation({ summary: 'List' })
  @ApiParam({ name: 'orderId', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  list(
    @CurrentUser() user: AuthenticatedUser,
    @Param('orderId') orderId: string,
  ) {
    return this.service.listForOrder(user.id, orderId, isAdmin(user));
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get refund status for an owned order' })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Refund status' })
  get(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.get(user.id, id, isAdmin(user));
  }

  @Patch(':id/approve')
  @ApiOperation({ summary: 'Approve' })
  @ApiBody({
    schema: { type: 'object', properties: { staffNote: { type: 'string' } } },
  })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  approve(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body('staffNote') staffNote?: string,
  ) {
    return this.service.approve(id, user.id, staffNote);
  }
}

function isAdmin(user: AuthenticatedUser): boolean {
  return typeof user.role === 'string'
    ? user.role === RoleEnum.ADMIN
    : user.role?.name === RoleEnum.ADMIN;
}
