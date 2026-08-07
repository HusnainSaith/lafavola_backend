import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { Notification } from './notification.entity';

@Entity('notification_deliveries')
export class NotificationDelivery {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'notification_id', type: 'uuid' })
  notificationId: string;

  @ManyToOne(() => Notification, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'notification_id' })
  notification: Notification;

  @Column({ name: 'channel', type: 'varchar', length: 20 })
  channel: string;

  @Column({ name: 'provider', type: 'varchar', length: 40, nullable: true })
  provider?: string;

  @Column({
    name: 'provider_message_id',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  providerMessageId?: string;

  @Column({
    name: 'destination_masked',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  destinationMasked?: string;

  @Column({ name: 'status', type: 'varchar', length: 30 })
  status: string;

  @Column({ name: 'attempts', type: 'integer' })
  attempts: number;

  @Column({ name: 'last_error', type: 'text', nullable: true })
  lastError?: string;

  @Column({ name: 'sent_at', type: 'timestamptz', nullable: true })
  sentAt?: Date;

  @Column({ name: 'delivered_at', type: 'timestamptz', nullable: true })
  deliveredAt?: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
