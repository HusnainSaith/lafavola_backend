import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Order } from '../../orders/entities/order.entity';
import { Promotion } from '../../promotions/entities/promotion.entity';
import { Coupon } from '../../coupons/entities/coupon.entity';

@Entity('notifications')
export class Notification {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid', nullable: true })
  userId?: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @Column({ name: 'order_id', type: 'uuid', nullable: true })
  orderId?: string;

  @ManyToOne(() => Order, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'order_id' })
  order?: Order;

  @Column({ name: 'promotion_id', type: 'uuid', nullable: true })
  promotionId?: string;

  @ManyToOne(() => Promotion, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'promotion_id' })
  promotion?: Promotion;

  @Column({ name: 'coupon_id', type: 'uuid', nullable: true })
  couponId?: string;

  @ManyToOne(() => Coupon, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'coupon_id' })
  coupon?: Coupon;

  @Column({ name: 'type', type: 'varchar', length: 50 })
  type: string;

  @Column({ name: 'title', type: 'varchar', length: 180 })
  title: string;

  @Column({ name: 'body', type: 'text' })
  body: string;

  @Column({ name: 'payload', type: 'jsonb' })
  payload: Record<string, unknown>;

  @Column({ name: 'read_at', type: 'timestamptz', nullable: true })
  readAt?: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
