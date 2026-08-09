import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { MenuItem } from '../../menu/entities/menu-item.entity';
import { OptionGroup } from '../../option-groups/entities/option-group.entity';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';

@Entity('pizza_builder_rules')
export class PizzaBuilderRule {
  @PrimaryGeneratedColumn('uuid')
  id: string;

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

  @Column({ name: 'name', type: 'varchar', length: 160 })
  name: string;

  @Column({ name: 'size_group_id', type: 'uuid', nullable: true })
  sizeGroupId?: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'size_group_id' })
  sizeGroup?: OptionGroup;

  @Column({ name: 'dough_group_id', type: 'uuid', nullable: true })
  doughGroupId?: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'dough_group_id' })
  doughGroup?: OptionGroup;

  @Column({ name: 'sauce_group_id', type: 'uuid', nullable: true })
  sauceGroupId?: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'sauce_group_id' })
  sauceGroup?: OptionGroup;

  @Column({ name: 'cheese_group_id', type: 'uuid', nullable: true })
  cheeseGroupId?: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'cheese_group_id' })
  cheeseGroup?: OptionGroup;

  @Column({ name: 'toppings_group_id', type: 'uuid', nullable: true })
  toppingsGroupId?: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'toppings_group_id' })
  toppingsGroup?: OptionGroup;

  @Column({ name: 'max_total_toppings', type: 'integer', nullable: true })
  maxTotalToppings?: number;

  @Column({ name: 'free_topping_count', type: 'integer' })
  freeToppingCount: number;

  @Column({ name: 'rule_config', type: 'jsonb' })
  ruleConfig: Record<string, unknown>;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
