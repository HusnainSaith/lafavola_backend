import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { UpdateNotificationPreferencesDto } from './dto/update-notification-preferences.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';

import { ApiBearerAuth, ApiBody, ApiOperation, ApiParam, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
@ApiTags('Notifications')
@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}

  @Get()
  @ApiOperation({ summary: 'List' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.service.list(user.id);
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Unread' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async unread(@CurrentUser() user: AuthenticatedUser) {
    return { count: await this.service.unreadCount(user.id) };
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'Mark Read' })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  markRead(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.markRead(user.id, id);
  }

  @Post('devices')
  @ApiOperation({ summary: 'Register Device' })
  @ApiBody({ type: RegisterDeviceTokenDto })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  registerDevice(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RegisterDeviceTokenDto,
  ) {
    return this.service.registerDevice(user.id, dto);
  }

  @Get('preferences/me')
  @ApiOperation({ summary: 'Preferences' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  preferences(@CurrentUser() user: AuthenticatedUser) {
    return this.service.preferences(user.id);
  }

  @Patch('preferences/me')
  @ApiOperation({ summary: 'Update Preferences' })
  @ApiBody({ type: UpdateNotificationPreferencesDto })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  updatePreferences(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateNotificationPreferencesDto,
  ) {
    return this.service.updatePreferences(user.id, dto);
  }
}
