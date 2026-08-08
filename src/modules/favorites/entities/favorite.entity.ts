import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { MenuItem } from '../../menu/entities/menu-item.entity';
import { OrderItem } from '../../orders/entities/order-item.entity';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { User } from '../../users/entities/user.entity';

@Entity('favorites')
export class Favorite {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'customer_id', type: 'uuid' })
  customerId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'customer_id' })
  customer: User;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'menu_item_id', type: 'uuid', nullable: true })
  menuItemId?: string;

  @ManyToOne(() => MenuItem, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem?: MenuItem;

  @Column({ name: 'source_order_item_id', type: 'uuid', nullable: true })
  sourceOrderItemId?: string;

  @ManyToOne(() => OrderItem, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'source_order_item_id' })
  sourceOrderItem?: OrderItem;

  @Column({ name: 'label', type: 'varchar', length: 120, nullable: true })
  label?: string;

  @Column({ name: 'configuration_snapshot', type: 'jsonb' })
  configurationSnapshot: Record<string, unknown>;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
