import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Notification } from '../entities/notification.entity';

@Injectable()
export class NotificationRepository extends BaseRepository<Notification> {
  constructor(dataSource: DataSource) {
    super(dataSource, Notification);
  }
}
