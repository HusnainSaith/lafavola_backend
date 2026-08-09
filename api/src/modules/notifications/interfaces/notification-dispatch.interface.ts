import { NotificationChannel } from '../enums/notification-channel.enum';
import { NotificationType } from '../enums/notification-type.enum';

export interface NotificationDispatchRequest {
  userId?: string;
  orderId?: string;
  type: NotificationType;
  title: string;
  body: string;
  channels: NotificationChannel[];
  payload?: Record<string, unknown>;
}
