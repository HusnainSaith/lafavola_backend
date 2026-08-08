import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  ParseBoolPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBody,
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RoleEnum } from '../roles/role.enum';
import { CollectPaymentDto } from './dto/collect-payment.dto';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { PaymentCheckoutResponseDto } from './dto/payment-checkout-response.dto';
import { SumUpWebhookDto } from './dto/sumup-webhook.dto';
import { PaymentsService } from './payments.service';

@ApiTags('Payments')
@ApiBearerAuth('JWT-auth')
@Controller('payments')
@UseGuards(JwtAuthGuard)
export class PaymentsController {
  constructor(private readonly service: PaymentsService) {}

  @Post('checkouts')
  @ApiOperation({
    summary: 'Create or reuse an online SumUp checkout for an owned order',
  })
  @ApiBody({ type: CreatePaymentIntentDto })
  @ApiResponse({ status: 201, type: PaymentCheckoutResponseDto })
  @ApiResponse({
    status: 409,
    description: 'Paid order or idempotency conflict',
  })
  @ApiResponse({
    status: 502,
    description: 'Payment provider rejected the request',
  })
  @ApiResponse({ status: 503, description: 'Payment provider unavailable' })
  createCheckout(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreatePaymentIntentDto,
  ) {
    return this.service.createCheckout(user.id, dto);
  }

  @Get('orders/:orderId/status')
  @ApiOperation({
    summary: 'Get an owned order payment status and optionally refresh SumUp',
  })
  @ApiParam({ name: 'orderId', type: String })
  @ApiQuery({ name: 'refresh', required: false, type: Boolean })
  @ApiResponse({ status: 200, type: PaymentCheckoutResponseDto })
  status(
    @CurrentUser() user: AuthenticatedUser,
    @Param('orderId') orderId: string,
    @Query('refresh', new ParseBoolPipe({ optional: true })) refresh?: boolean,
  ) {
    return this.service.getOrderPaymentStatus(
      user.id,
      orderId,
      refresh ?? true,
    );
  }

  @Public()
  @Post('webhooks/sumup')
  @HttpCode(204)
  @ApiOperation({
    summary: 'Receive SumUp notifications; state is verified through SumUp',
  })
  @ApiResponse({ status: 204, description: 'Notification accepted' })
  webhook(@Body() dto: SumUpWebhookDto) {
    return this.service.handleSumUpWebhook(dto);
  }

  @Post('orders/:id/collect')
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN, RoleEnum.EMPLOYEE)
  @ApiOperation({
    summary: 'Record cash or external-terminal collection on delivery',
  })
  @ApiBody({ type: CollectPaymentDto })
  @ApiResponse({ status: 201, type: PaymentCheckoutResponseDto })
  collect(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: CollectPaymentDto,
  ) {
    return this.service.collectOnDelivery(
      id,
      user.id,
      dto,
      typeof user.role === 'object' && user.role?.name === RoleEnum.ADMIN,
    );
  }
}
