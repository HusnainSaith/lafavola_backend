import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { UpdateNotificationPreferencesDto } from './dto/update-notification-preferences.dto';
import { DeviceToken } from './entities/device-token.entity';
import { NotificationPreference } from './entities/notification-preference.entity';
import { Notification } from './entities/notification.entity';
import { NotificationRepository } from './repositories/notification.repository';

@Injectable()
export class NotificationsService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly notifications: NotificationRepository,
  ) {}
  list(userId: string, page = 1, limit = 50) {
    return this.notifications.findMany({
      where: { userId },
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
  }
  unreadCount(userId: string) {
    return this.dataSource
      .getRepository(Notification)
      .createQueryBuilder('notification')
      .where('notification.user_id=:userId', { userId })
      .andWhere('notification.read_at IS NULL')
      .getCount();
  }
  async markRead(userId: string, id: string) {
    const notification = await this.notifications.findOne({
      where: { id, userId },
    });
    if (!notification) throw new NotFoundException('Notification not found');
    notification.readAt = new Date();
    return this.notifications.save(notification);
  }
  async registerDevice(userId: string, dto: RegisterDeviceTokenDto) {
    const repo = this.dataSource.getRepository(DeviceToken);
    let token = await repo.findOne({ where: { token: dto.token } });
    if (token && token.userId !== userId)
      throw new ConflictException('Device token is already registered');
    token ??= repo.create({ userId, provider: 'fcm', token: dto.token });
    token.platform = dto.platform;
    token.isActive = true;
    token.lastSeenAt = new Date();
    return repo.save(token);
  }
  async deactivateDevice(userId: string, id: string) {
    const repo = this.dataSource.getRepository(DeviceToken);
    const token = await repo.findOne({ where: { id, userId } });
    if (!token) throw new NotFoundException('Device token not found');
    token.isActive = false;
    return repo.save(token);
  }
  async preferences(userId: string) {
    const repo = this.dataSource.getRepository(NotificationPreference);
    let preferences = await repo.findOne({ where: { userId } });
    preferences ??= await repo.save(repo.create({ userId }));
    return preferences;
  }
  async updatePreferences(
    userId: string,
    dto: UpdateNotificationPreferencesDto,
  ) {
    const repo = this.dataSource.getRepository(NotificationPreference);
    const preferences = await this.preferences(userId);
    Object.assign(preferences, dto);
    return repo.save(preferences);
  }
}
