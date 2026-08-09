import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';

@Entity('daily_sales_metrics')
export class DailySalesMetric {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'metric_date', type: 'date' })
  metricDate: string;

  @Column({ name: 'total_orders', type: 'integer' })
  totalOrders: number;

  @Column({ name: 'delivered_orders', type: 'integer' })
  deliveredOrders: number;

  @Column({ name: 'cancelled_orders', type: 'integer' })
  cancelledOrders: number;

  @Column({ name: 'gross_revenue_minor', type: 'bigint' })
  grossRevenueMinor: string;

  @Column({ name: 'discounts_minor', type: 'bigint' })
  discountsMinor: string;

  @Column({ name: 'refunds_minor', type: 'bigint' })
  refundsMinor: string;

  @Column({ name: 'delivery_fees_minor', type: 'bigint' })
  deliveryFeesMinor: string;

  @Column({ name: 'tax_minor', type: 'bigint' })
  taxMinor: string;

  @Column({ name: 'net_revenue_minor', type: 'bigint' })
  netRevenueMinor: string;

  @Column({ name: 'average_order_value_minor', type: 'integer' })
  averageOrderValueMinor: number;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
