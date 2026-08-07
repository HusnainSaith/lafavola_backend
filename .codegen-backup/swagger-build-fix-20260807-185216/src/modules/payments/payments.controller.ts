import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { SavePaymentMethodDto } from './dto/save-payment-method.dto';
import { CollectPaymentDto } from './dto/collect-payment.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

import { ApiBearerAuth, ApiBody, ApiOperation, ApiParam, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';

@ApiTags('Payments')
@Controller('payments')
@UseGuards(JwtAuthGuard)
export class PaymentsController {
  constructor(private readonly service: PaymentsService) {}

  @Get('methods')
  @ApiOperation({ summary: 'Methods' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  methods(@CurrentUser() user: AuthenticatedUser) {
    return this.service.listMethods(user.id);
  }

  @Post('methods')
  @ApiOperation({ summary: 'Save Method' })
  @ApiBody({ type: SavePaymentMethodDto })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  saveMethod(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: SavePaymentMethodDto,
  ) {
    return this.service.saveMethod(user.id, dto);
  }

  @Post('intent')
  @ApiOperation({ summary: 'Create Intent' })
  @ApiBody({ type: CreatePaymentIntentDto })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  createIntent(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreatePaymentIntentDto,
  ) {
    return this.service.createIntent(user.id, dto);
  }

  @Post('orders/:id/collect')
  @ApiOperation({ summary: 'Collect' })
  @ApiBody({ type: CollectPaymentDto })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  collect(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: CollectPaymentDto,
  ) {
    return this.service.collectOnDelivery(id, user.id, dto);
  }
}
