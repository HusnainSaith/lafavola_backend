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

import { ApiBearerAuth, ApiBody, ApiOperation, ApiParam, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
@ApiTags('Support')
@Controller('support')
@UseGuards(JwtAuthGuard)
export class SupportController {
  constructor(private readonly service: SupportService) {}

  @Get('tickets')
  @ApiOperation({ summary: 'List' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.service.listCustomer(user.id);
  }

  @Post('tickets')
  @ApiOperation({ summary: 'Create' })
  @ApiBody({ type: CreateSupportTicketDto })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateSupportTicketDto,
  ) {
    return this.service.create(user.id, dto);
  }

  @Get('tickets/:id')
  @ApiOperation({ summary: 'Detail' })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  detail(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.detail(user.id, id);
  }

  @Post('tickets/:id/messages')
  @ApiOperation({ summary: 'Message' })
  @ApiBody({ type: CreateSupportMessageDto })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  message(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: CreateSupportMessageDto,
  ) {
    return this.service.addCustomerMessage(user.id, id, dto);
  }

  @Get('admin/tickets')
  @ApiOperation({ summary: 'Admin List' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  adminList() {
    return this.service.listAdmin();
  }

  @Patch('admin/tickets/:id')
  @ApiOperation({ summary: 'Admin Update' })
  @ApiBody({ type: UpdateSupportTicketDto })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  adminUpdate(@Param('id') id: string, @Body() dto: UpdateSupportTicketDto) {
    return this.service.updateAdmin(id, dto);
  }
}
