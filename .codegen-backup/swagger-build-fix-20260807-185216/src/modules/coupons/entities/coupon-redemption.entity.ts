import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { Coupon } from './coupon.entity';
import { User } from '../../users/entities/user.entity';

@Entity('coupon_redemptions')
export class CouponRedemption {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'coupon_id', type: 'uuid' })
  couponId: string;

  @ManyToOne(() => Coupon, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'coupon_id' })
  coupon: Coupon;

  @Column({ name: 'customer_id', type: 'uuid', nullable: true })
  customerId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'customer_id' })
  customer?: User;

  @Column({ name: 'order_id', type: 'uuid', nullable: true })
  orderId?: string;

  @Column({ name: 'discount_minor', type: 'integer' })
  discountMinor: number;

  @Column({ name: 'redeemed_at', type: 'timestamptz' })
  redeemedAt: Date;
}
