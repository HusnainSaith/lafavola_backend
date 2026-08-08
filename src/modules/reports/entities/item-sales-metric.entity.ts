import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { MenuItem } from '../../menu/entities/menu-item.entity';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';

@Entity('item_sales_metrics')
export class ItemSalesMetric {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'menu_item_id', type: 'uuid', nullable: true })
  menuItemId?: string;

  @ManyToOne(() => MenuItem, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem?: MenuItem;

  @Column({ name: 'metric_date', type: 'date' })
  metricDate: string;

  @Column({ name: 'item_name_snapshot', type: 'varchar', length: 180 })
  itemNameSnapshot: string;

  @Column({ name: 'quantity_sold', type: 'integer' })
  quantitySold: number;

  @Column({ name: 'revenue_minor', type: 'bigint' })
  revenueMinor: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
