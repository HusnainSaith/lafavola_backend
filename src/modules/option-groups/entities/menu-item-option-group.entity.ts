import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { MenuItem } from '../../menu/entities/menu-item.entity';
import { OptionGroup } from './option-group.entity';

@Entity('menu_item_option_groups')
export class MenuItemOptionGroup {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'menu_item_id', type: 'uuid' })
  menuItemId: string;

  @ManyToOne(() => MenuItem, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem: MenuItem;

  @Column({ name: 'option_group_id', type: 'uuid' })
  optionGroupId: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'option_group_id' })
  optionGroup: OptionGroup;

  @Column({ name: 'min_select_override', type: 'integer', nullable: true })
  minSelectOverride?: number;

  @Column({ name: 'max_select_override', type: 'integer', nullable: true })
  maxSelectOverride?: number;

  @Column({ name: 'display_order', type: 'integer' })
  displayOrder: number;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
