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
import {
  ApiBody,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RoleEnum } from '../roles/role.enum';
import { CreateSupportMessageDto } from './dto/create-support-message.dto';
import { CreateSupportTicketDto } from './dto/create-support-ticket.dto';
import { UpdateSupportTicketDto } from './dto/update-support-ticket.dto';
import { SupportService } from './support.service';

@ApiTags('Support')
@Controller('support')
@UseGuards(JwtAuthGuard)
export class SupportController {
  constructor(private readonly service: SupportService) {}

  @Get('tickets')
  @ApiOperation({ summary: 'List authenticated customer conversations' })
  list(
    @CurrentUser() user: AuthenticatedUser,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    return this.service.listCustomer(
      user.id,
      Math.max(1, Number(page)),
      Math.min(100, Math.max(1, Number(limit))),
    );
  }

  @Post('tickets')
  @ApiOperation({ summary: 'Open a customer support conversation' })
  @ApiBody({ type: CreateSupportTicketDto })
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateSupportTicketDto,
  ) {
    return this.service.create(user.id, dto);
  }

  @Get('tickets/:id')
  @ApiOperation({ summary: 'Get an authorized conversation and unread count' })
  @ApiParam({ name: 'id' })
  detail(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.detail(user.id, id, role(user));
  }

  @Get('tickets/:id/messages')
  @ApiOperation({
    summary: 'Get paginated chronological conversation messages',
  })
  history(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Query('page') page = '1',
    @Query('limit') limit = '50',
  ) {
    return this.service.history(
      user.id,
      id,
      role(user),
      Math.max(1, Number(page)),
      Math.min(100, Math.max(1, Number(limit))),
    );
  }

  @Post('tickets/:id/messages')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  @ApiOperation({ summary: 'Persist and enqueue a support message' })
  @ApiBody({ type: CreateSupportMessageDto })
  @ApiResponse({
    status: 409,
    description: 'Conversation is resolved or closed',
  })
  message(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: CreateSupportMessageDto,
  ) {
    return this.service.addMessage(user.id, id, role(user), dto);
  }

  @Patch('tickets/:id/read')
  @ApiOperation({ summary: 'Mark the authorized side of a conversation read' })
  markRead(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.markRead(user.id, id, role(user));
  }

  @Get('tickets/:id/realtime-authorization')
  @ApiOperation({
    summary:
      'Authorize the authenticated user for a private AppSync conversation channel',
  })
  realtimeAuthorization(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.service.realtimeAuthorization(user.id, id, role(user));
  }

  @Get('agent/queue')
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN, RoleEnum.SUPPORT)
  @ApiOperation({ summary: 'Get filtered, paginated support queue' })
  queue(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: Record<string, string>,
  ) {
    return this.service.queue(user.id, {
      page: Number(query.page) || 1,
      limit: Math.min(100, Number(query.limit) || 20),
      assigned: query.assigned,
      status: query.status,
      priority: query.priority,
    });
  }

  @Post('agent/tickets/:id/claim')
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN, RoleEnum.SUPPORT)
  @ApiOperation({
    summary: 'Atomically claim an unassigned support conversation',
  })
  claim(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.claim(user.id, id);
  }

  @Patch('agent/tickets/:id/status')
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN, RoleEnum.SUPPORT)
  @ApiOperation({
    summary: 'Resolve, close, or update an assigned conversation',
  })
  status(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateSupportTicketDto,
  ) {
    if (!dto.status) return this.service.detail(user.id, id, role(user));
    return this.service.changeStatus(user.id, id, role(user), dto.status);
  }
}

function role(user: AuthenticatedUser): string {
  return typeof user.role === 'string'
    ? user.role
    : (user.role?.name ?? 'customer');
}
