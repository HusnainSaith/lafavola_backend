import {
  Column,
  Entity,
  JoinColumn,
  OneToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('notification_preferences')
export class NotificationPreference {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid', unique: true })
  userId: string;

  @OneToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'push_order_updates', type: 'boolean' })
  pushOrderUpdates: boolean;

  @Column({ name: 'sms_order_updates', type: 'boolean' })
  smsOrderUpdates: boolean;

  @Column({ name: 'email_order_updates', type: 'boolean' })
  emailOrderUpdates: boolean;

  @Column({ name: 'push_promotions', type: 'boolean' })
  pushPromotions: boolean;

  @Column({ name: 'sms_promotions', type: 'boolean' })
  smsPromotions: boolean;

  @Column({ name: 'email_promotions', type: 'boolean' })
  emailPromotions: boolean;

  @Column({ name: 'coupon_expiration_alerts', type: 'boolean' })
  couponExpirationAlerts: boolean;

  @Column({ name: 'quiet_hours_start', type: 'time', nullable: true })
  quietHoursStart?: string;

  @Column({ name: 'quiet_hours_end', type: 'time', nullable: true })
  quietHoursEnd?: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
