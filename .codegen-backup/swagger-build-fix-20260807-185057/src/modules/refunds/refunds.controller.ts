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

@Controller('refunds')
@UseGuards(JwtAuthGuard)
export class RefundsController {
  constructor(private readonly service: RefundsService) {}

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateRefundDto) {
    return this.service.create(user.id, dto);
  }

  @Get('orders/:orderId')
  list(@Param('orderId') orderId: string) {
    return this.service.listForOrder(orderId);
  }

  @Patch(':id/approve')
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  approve(@Param('id') id: string, @Body('staffNote') staffNote?: string) {
    return this.service.approve(id, staffNote);
  }
}
