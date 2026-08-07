import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { Cart } from './cart.entity';
import { MenuItem } from '../../menu/entities/menu-item.entity';
import { MenuItemSize } from '../../menu/entities/menu-item-size.entity';

@Entity('cart_items')
export class CartItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'cart_id', type: 'uuid' })
  cartId: string;

  @ManyToOne(() => Cart, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'cart_id' })
  cart: Cart;

  @Column({ name: 'menu_item_id', type: 'uuid' })
  menuItemId: string;

  @ManyToOne(() => MenuItem, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem: MenuItem;

  @Column({ name: 'menu_item_size_id', type: 'uuid', nullable: true })
  menuItemSizeId?: string;

  @ManyToOne(() => MenuItemSize, { onDelete: 'RESTRICT', nullable: true })
  @JoinColumn({ name: 'menu_item_size_id' })
  menuItemSize?: MenuItemSize;

  @Column({ name: 'quantity', type: 'integer' })
  quantity: number;

  @Column({ name: 'item_name_snapshot', type: 'varchar', length: 180 })
  itemNameSnapshot: string;

  @Column({
    name: 'size_name_snapshot',
    type: 'varchar',
    length: 80,
    nullable: true,
  })
  sizeNameSnapshot?: string;

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

  @Column({
    name: 'configuration_hash',
    type: 'varchar',
    length: 128,
    nullable: true,
  })
  configurationHash?: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
