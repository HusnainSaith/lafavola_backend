import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { RefundsService } from './refunds.service';
import { CreateRefundDto } from './dto/create-refund.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

import { ApiBearerAuth, ApiBody, ApiOperation, ApiParam, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';

@ApiTags('Refunds')
@Controller('refunds')
@UseGuards(JwtAuthGuard)
export class RefundsController {
  constructor(private readonly service: RefundsService) {}

  @Post()
  @ApiOperation({ summary: 'Create' })
  @ApiBody({ type: CreateRefundDto })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateRefundDto) {
    return this.service.create(user.id, dto);
  }

  @Get('orders/:orderId')
  @ApiOperation({ summary: 'List' })
  @ApiParam({ name: 'orderId', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  list(@Param('orderId') orderId: string) {
    return this.service.listForOrder(orderId);
  }

  @Patch(':id/approve')
  @ApiOperation({ summary: 'Approve' })
  @ApiBody({ schema: { type: 'object', properties: { staffNote: { type: 'string' } } } })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  approve(@Param('id') id: string, @Body('staffNote') staffNote?: string) {
    return this.service.approve(id, staffNote);
  }
}
