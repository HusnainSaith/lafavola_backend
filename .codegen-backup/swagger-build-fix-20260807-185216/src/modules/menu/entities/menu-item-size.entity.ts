import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { MenuItem } from './menu-item.entity';

@Entity('menu_item_sizes')
export class MenuItemSize {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'menu_item_id', type: 'uuid' })
  menuItemId: string;

  @ManyToOne(() => MenuItem, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem: MenuItem;

  @Column({ name: 'size_code', type: 'varchar', length: 30 })
  sizeCode: string;

  @Column({ name: 'display_name', type: 'varchar', length: 80 })
  displayName: string;

  @Column({ name: 'base_price_minor', type: 'integer' })
  basePriceMinor: number;

  @Column({ name: 'calories', type: 'integer', nullable: true })
  calories?: number;

  @Column({ name: 'display_order', type: 'integer' })
  displayOrder: number;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
