import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { SupportService } from './support.service';
import { CreateSupportTicketDto } from './dto/create-support-ticket.dto';
import { CreateSupportMessageDto } from './dto/create-support-message.dto';
import { UpdateSupportTicketDto } from './dto/update-support-ticket.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('support')
@UseGuards(JwtAuthGuard)
export class SupportController {
  constructor(private readonly service: SupportService) {}

  @Get('tickets')
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.service.listCustomer(user.id);
  }

  @Post('tickets')
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateSupportTicketDto,
  ) {
    return this.service.create(user.id, dto);
  }

  @Get('tickets/:id')
  detail(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.detail(user.id, id);
  }

  @Post('tickets/:id/messages')
  message(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: CreateSupportMessageDto,
  ) {
    return this.service.addCustomerMessage(user.id, id, dto);
  }

  @Get('admin/tickets')
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  adminList() {
    return this.service.listAdmin();
  }

  @Patch('admin/tickets/:id')
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  adminUpdate(@Param('id') id: string, @Body() dto: UpdateSupportTicketDto) {
    return this.service.updateAdmin(id, dto);
  }
}
