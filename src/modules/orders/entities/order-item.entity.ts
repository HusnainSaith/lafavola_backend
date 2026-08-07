import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { Order } from './order.entity';
import { MenuItem } from '../../menu/entities/menu-item.entity';
import { MenuItemSize } from '../../menu/entities/menu-item-size.entity';

@Entity('order_items')
export class OrderItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_id', type: 'uuid' })
  orderId: string;

  @ManyToOne(() => Order, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({ name: 'menu_item_id', type: 'uuid', nullable: true })
  menuItemId?: string;

  @ManyToOne(() => MenuItem, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem?: MenuItem;

  @Column({ name: 'menu_item_size_id', type: 'uuid', nullable: true })
  menuItemSizeId?: string;

  @ManyToOne(() => MenuItemSize, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'menu_item_size_id' })
  menuItemSize?: MenuItemSize;

  @Column({ name: 'item_name_snapshot', type: 'varchar', length: 180 })
  itemNameSnapshot: string;

  @Column({
    name: 'size_name_snapshot',
    type: 'varchar',
    length: 80,
    nullable: true,
  })
  sizeNameSnapshot?: string;

  @Column({ name: 'quantity', type: 'integer' })
  quantity: number;

  @Column({ name: 'base_unit_price_minor', type: 'integer' })
  baseUnitPriceMinor: number;

  @Column({ name: 'options_unit_price_minor', type: 'integer' })
  optionsUnitPriceMinor: number;

  @Column({ name: 'unit_price_minor', type: 'integer' })
  unitPriceMinor: number;

  @Column({ name: 'line_total_minor', type: 'integer' })
  lineTotalMinor: number;

  @Column({ name: 'special_instructions', type: 'text', nullable: true })
  specialInstructions?: string;

  @Column({ name: 'configuration_snapshot', type: 'jsonb' })
  configurationSnapshot: Record<string, unknown>;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
