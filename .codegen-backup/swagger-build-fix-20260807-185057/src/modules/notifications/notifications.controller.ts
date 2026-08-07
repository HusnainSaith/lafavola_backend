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

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}

  @Get()
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.service.list(user.id);
  }

  @Get('unread-count')
  async unread(@CurrentUser() user: AuthenticatedUser) {
    return { count: await this.service.unreadCount(user.id) };
  }

  @Patch(':id/read')
  markRead(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.markRead(user.id, id);
  }

  @Post('devices')
  registerDevice(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RegisterDeviceTokenDto,
  ) {
    return this.service.registerDevice(user.id, dto);
  }

  @Get('preferences/me')
  preferences(@CurrentUser() user: AuthenticatedUser) {
    return this.service.preferences(user.id);
  }

  @Patch('preferences/me')
  updatePreferences(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateNotificationPreferencesDto,
  ) {
    return this.service.updatePreferences(user.id, dto);
  }
}
