import { Inject, Injectable, Logger } from '@nestjs/common';
import { DataSource } from 'typeorm';
import {
  MAIL_PROVIDER,
  MailProvider,
} from '../integrations/mail/mail.interface';
import { orderTemplate } from '../integrations/mail/templates/template.util';
import {
  PUSH_PROVIDER,
  PushNotificationProvider,
} from '../integrations/push/push.interface';
import {
  REALTIME_PROVIDER,
  RealtimeMessagingProvider,
} from '../integrations/realtime/realtime.interface';
import { OutboxEvent } from '../modules/audit/entities/outbox-event.entity';
import { DeviceToken } from '../modules/notifications/entities/device-token.entity';
import { NotificationDelivery } from '../modules/notifications/entities/notification-delivery.entity';
import { NotificationPreference } from '../modules/notifications/entities/notification-preference.entity';
import { Notification } from '../modules/notifications/entities/notification.entity';

@Injectable()
export class OutboxWorker {
  private readonly logger = new Logger(OutboxWorker.name);
  constructor(
    private readonly dataSource: DataSource,
    @Inject(MAIL_PROVIDER) private readonly mail: MailProvider,
    @Inject(REALTIME_PROVIDER)
    private readonly realtime: RealtimeMessagingProvider,
    @Inject(PUSH_PROVIDER) private readonly push: PushNotificationProvider,
  ) {}

  async processBatch(limit = 20): Promise<number> {
    const events = await this.dataSource.transaction(async (manager) => {
      const repository = manager.getRepository(OutboxEvent);
      const claimed = await repository
        .createQueryBuilder('event')
        .setLock('pessimistic_write')
        .setOnLocked('skip_locked')
        .where(
          "(event.status IN ('pending','failed') OR (event.status='processing' AND event.claimed_at < NOW() - (:claimTimeout * INTERVAL '1 millisecond')))",
          {
            claimTimeout: Number(process.env.WORKER_CLAIM_TIMEOUT_MS ?? 300000),
          },
        )
        .andWhere('event.available_at <= NOW()')
        .orderBy('event.created_at', 'ASC')
        .take(limit)
        .getMany();
      for (const event of claimed) {
        event.status = 'processing';
        event.claimedAt = new Date();
        event.attempts += 1;
      }
      return repository.save(claimed);
    });
    for (const event of events) {
      try {
        await this.handle(event);
        await this.dataSource.getRepository(OutboxEvent).update(event.id, {
          status: 'published',
          publishedAt: new Date(),
          lastError: undefined,
        });
      } catch {
        const dead = event.attempts >= 5;
        await this.dataSource.getRepository(OutboxEvent).update(event.id, {
          status: dead ? 'dead_letter' : 'failed',
          availableAt: new Date(Date.now() + 2 ** event.attempts * 60_000),
          lastError: 'Provider delivery failed',
        });
        this.logger.warn(`Outbox event ${event.id} delivery failed`);
      }
    }
    return events.length;
  }

  private async handle(event: OutboxEvent) {
    if (event.eventType.startsWith('support.'))
      return this.handleSupport(event);
    if (event.eventType === 'delivery.status_changed')
      return this.handleDelivery(event);
    if (['order.confirmed', 'order.status_changed'].includes(event.eventType))
      return this.handleOrder(event);
  }

  private async handleDelivery(event: OutboxEvent) {
    if (event.payload.status !== 'arriving') return;
    const orderId = String(event.payload.orderId ?? '');
    const rows = await this.dataSource.query(
      `SELECT customer_id AS "customerId" FROM orders WHERE id=$1`,
      [orderId],
    );
    if (!rows[0]?.customerId) return;
    await this.persistAndPush(
      rows[0].customerId,
      event.id,
      'driver_arriving',
      'Driver arriving',
      'Your driver is approaching the delivery address.',
      { orderId, status: 'arriving' },
    );
  }

  private async handleSupport(event: OutboxEvent) {
    const ticketId = String(event.payload.ticketId ?? '');
    if (!ticketId) return;
    const rows = await this.dataSource.query(
      `SELECT t.customer_id AS "customerId",t.assigned_staff_user_id AS "agentId",m.id AS "messageId",m.body,m.author_type AS "authorType",m.created_at AS "createdAt"
       FROM support_tickets t LEFT JOIN support_messages m ON m.id=$2 WHERE t.id=$1`,
      [ticketId, event.payload.messageId ?? null],
    );
    const row = rows[0];
    if (!row) return;
    await this.realtime.publish(`/support/${ticketId}`, {
      id: event.id,
      type: event.eventType as any,
      ticketId,
      data: {
        messageId: row.messageId,
        body: row.body,
        authorType: row.authorType,
      },
      occurredAt: new Date(row.createdAt ?? Date.now()).toISOString(),
    });
    if (
      event.eventType === 'support.message.created' &&
      row.authorType === 'customer'
    ) {
      await this.realtime.publish('/support/queue', {
        id: event.id,
        type: event.eventType,
        ticketId,
        data: { ticketId },
        occurredAt: new Date().toISOString(),
      });
    }
    if (
      event.eventType === 'support.message.created' &&
      row.authorType === 'staff' &&
      row.customerId
    ) {
      await this.persistAndPush(
        row.customerId,
        event.id,
        'support_reply',
        'Support replied',
        'You have a new support message',
        { ticketId },
      );
    }
  }

  private async handleOrder(event: OutboxEvent) {
    const orderId = String(event.payload.orderId ?? '');
    const rows = await this.dataSource.query(
      `SELECT u.id AS "userId",u.email,o.order_number AS "orderNumber",o.status FROM orders o LEFT JOIN users u ON u.id=o.customer_id WHERE o.id=$1`,
      [orderId],
    );
    const order = rows[0];
    if (!order) return;
    if (order.email) {
      const template = orderTemplate({
        heading:
          event.eventType === 'order.confirmed'
            ? 'Your La Favola order is confirmed'
            : 'Your La Favola order was updated',
        orderNumber: order.orderNumber,
        status: order.status.replace(/_/g, ' '),
      });
      await this.mail.send({
        to: order.email,
        subject: `La Favola order ${order.orderNumber}`,
        idempotencyKey: event.id,
        ...template,
      });
    }
    if (!order.userId) return;
    const mapped = this.orderNotification(order.status, event.eventType);
    if (mapped)
      await this.persistAndPush(
        order.userId,
        event.id,
        mapped.type,
        mapped.title,
        mapped.body,
        { orderId, status: order.status },
        false,
      );
  }

  private async persistAndPush(
    userId: string,
    eventKey: string,
    type: string,
    title: string,
    body: string,
    payload: Record<string, string>,
    marketing = false,
  ) {
    const repo = this.dataSource.getRepository(Notification);
    let notification = await repo.findOne({ where: { userId, eventKey } });
    if (!notification)
      notification = await repo.save(
        repo.create({ userId, eventKey, type, title, body, payload }),
      );
    const pref = await this.dataSource
      .getRepository(NotificationPreference)
      .findOne({ where: { userId } });
    if (
      (marketing && pref?.pushPromotions === false) ||
      (!marketing &&
        type !== 'support_reply' &&
        pref?.pushOrderUpdates === false)
    )
      return;
    const tokens = await this.dataSource
      .getRepository(DeviceToken)
      .find({ where: { userId, isActive: true } });
    for (const token of tokens) {
      const deliveryRepo = this.dataSource.getRepository(NotificationDelivery);
      let delivery = await deliveryRepo.findOne({
        where: { notificationId: notification.id, deviceTokenId: token.id },
      });
      if (delivery?.status === 'sent' || delivery?.status === 'skipped')
        continue;
      delivery ??= deliveryRepo.create({
        notificationId: notification.id,
        deviceTokenId: token.id,
        channel: 'push',
        provider: 'fcm',
        status: 'pending',
        attempts: 0,
        destinationMasked: `device:${token.id.slice(0, 8)}`,
      });
      delivery.attempts += 1;
      const result = await this.push.sendToDevice(token.token, {
        title,
        body,
        data: payload,
      });
      if (result.permanentFailure) {
        token.isActive = false;
        await this.dataSource.getRepository(DeviceToken).save(token);
        delivery.status = 'skipped';
        delivery.lastError = 'Device token is no longer registered';
      } else {
        delivery.status = 'sent';
        delivery.providerMessageId = result.messageId;
        delivery.sentAt = new Date();
      }
      await deliveryRepo.save(delivery);
    }
  }

  private orderNotification(status: string, eventType: string) {
    if (eventType === 'order.confirmed' || status === 'placed')
      return {
        type: 'order_confirmed',
        title: 'Order confirmed',
        body: 'Your La Favola order is confirmed.',
      };
    if (status === 'preparing')
      return {
        type: 'order_preparing',
        title: 'Pizza preparing',
        body: 'Your pizza is being prepared.',
      };
    if (status === 'out_for_delivery')
      return {
        type: 'order_out_for_delivery',
        title: 'On the way',
        body: 'Your order is out for delivery.',
      };
    if (status === 'delivered')
      return {
        type: 'order_delivered',
        title: 'Order delivered',
        body: 'Your order has been delivered.',
      };
    return null;
  }
}
