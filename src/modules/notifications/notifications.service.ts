import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { NotificationRepository } from './repositories/notification.repository';
import { Notification } from './entities/notification.entity';
import { DeviceToken } from './entities/device-token.entity';
import { NotificationPreference } from './entities/notification-preference.entity';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { UpdateNotificationPreferencesDto } from './dto/update-notification-preferences.dto';

@Injectable()
export class NotificationsService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly notifications: NotificationRepository,
  ) {}

  list(userId: string) {
    return this.notifications.findMany({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: 100,
    });
  }

  async unreadCount(userId: string): Promise<number> {
    return this.dataSource
      .getRepository(Notification)
      .createQueryBuilder('notification')
      .where('notification.user_id = :userId', { userId })
      .andWhere('notification.read_at IS NULL')
      .getCount();
  }

  async markRead(userId: string, id: string) {
    const notification = await this.notifications.findOne({
      where: { id, userId },
    });
    if (!notification) return null;
    notification.readAt = new Date();
    return this.notifications.save(notification);
  }

  async registerDevice(userId: string, dto: RegisterDeviceTokenDto) {
    const repo = this.dataSource.getRepository(DeviceToken);
    let token = await repo.findOne({ where: { token: dto.token } });
    if (!token) {
      token = repo.create({
        userId,
        platform: dto.platform,
        provider: 'fcm',
        token: dto.token,
        isActive: true,
        lastSeenAt: new Date(),
      });
    } else {
      token.userId = userId;
      token.platform = dto.platform;
      token.isActive = true;
      token.lastSeenAt = new Date();
    }
    return repo.save(token);
  }

  async preferences(userId: string) {
    const repo = this.dataSource.getRepository(NotificationPreference);
    let preferences = await repo.findOne({ where: { userId } });
    if (!preferences) {
      preferences = await repo.save(repo.create({ userId }));
    }
    return preferences;
  }

  async updatePreferences(
    userId: string,
    dto: UpdateNotificationPreferencesDto,
  ) {
    const repo = this.dataSource.getRepository(NotificationPreference);
    let preferences = await this.preferences(userId);
    Object.assign(preferences, dto);
    return repo.save(preferences);
  }
}
