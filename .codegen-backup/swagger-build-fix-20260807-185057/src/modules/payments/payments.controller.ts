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

@Controller('payments')
@UseGuards(JwtAuthGuard)
export class PaymentsController {
  constructor(private readonly service: PaymentsService) {}

  @Get('methods')
  methods(@CurrentUser() user: AuthenticatedUser) {
    return this.service.listMethods(user.id);
  }

  @Post('methods')
  saveMethod(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: SavePaymentMethodDto,
  ) {
    return this.service.saveMethod(user.id, dto);
  }

  @Post('intent')
  createIntent(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreatePaymentIntentDto,
  ) {
    return this.service.createIntent(user.id, dto);
  }

  @Post('orders/:id/collect')
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
