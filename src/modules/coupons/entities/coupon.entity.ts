import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Promotion } from '../../promotions/entities/promotion.entity';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';

@Entity('coupons')
export class Coupon {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'promotion_id', type: 'uuid', nullable: true })
  promotionId?: string;

  @ManyToOne(() => Promotion, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'promotion_id' })
  promotion?: Promotion;

  @Column({ name: 'code', type: 'varchar', length: 80 })
  code: string;

  @Column({ name: 'description', type: 'text', nullable: true })
  description?: string;

  @Column({ name: 'discount_type', type: 'varchar', length: 30 })
  discountType: string;

  @Column({ name: 'discount_value', type: 'integer' })
  discountValue: number;

  @Column({ name: 'min_order_minor', type: 'integer' })
  minOrderMinor: number;

  @Column({ name: 'max_discount_minor', type: 'integer', nullable: true })
  maxDiscountMinor?: number;

  @Column({ name: 'starts_at', type: 'timestamptz', nullable: true })
  startsAt?: Date;

  @Column({ name: 'expires_at', type: 'timestamptz', nullable: true })
  expiresAt?: Date;

  @Column({ name: 'total_usage_limit', type: 'integer', nullable: true })
  totalUsageLimit?: number;

  @Column({ name: 'per_customer_limit', type: 'integer', nullable: true })
  perCustomerLimit?: number;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
