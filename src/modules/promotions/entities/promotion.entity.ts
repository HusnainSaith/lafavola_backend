import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';

@Entity('promotions')
export class Promotion {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'name', type: 'varchar', length: 180 })
  name: string;

  @Column({ name: 'description', type: 'text', nullable: true })
  description?: string;

  @Column({ name: 'promotion_type', type: 'varchar', length: 40 })
  promotionType: string;

  @Column({ name: 'discount_value', type: 'integer' })
  discountValue: number;

  @Column({ name: 'min_order_minor', type: 'integer' })
  minOrderMinor: number;

  @Column({ name: 'max_discount_minor', type: 'integer', nullable: true })
  maxDiscountMinor?: number;

  @Column({ name: 'starts_at', type: 'timestamptz' })
  startsAt: Date;

  @Column({ name: 'ends_at', type: 'timestamptz', nullable: true })
  endsAt?: Date;

  @Column({ name: 'days_of_week', type: 'smallint', array: true })
  daysOfWeek: number[];

  @Column({ name: 'total_usage_limit', type: 'integer', nullable: true })
  totalUsageLimit?: number;

  @Column({ name: 'per_customer_limit', type: 'integer', nullable: true })
  perCustomerLimit?: number;

  @Column({ name: 'priority', type: 'integer' })
  priority: number;

  @Column({
    name: 'stacking_group',
    type: 'varchar',
    length: 80,
    nullable: true,
  })
  stackingGroup?: string;

  @Column({ name: 'is_automatic', type: 'boolean' })
  isAutomatic: boolean;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'conditions', type: 'jsonb' })
  conditions: Record<string, unknown>;

  @Column({ name: 'actions', type: 'jsonb' })
  actions: Record<string, unknown>;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
