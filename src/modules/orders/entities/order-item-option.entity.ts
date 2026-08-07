import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { OrderItem } from './order-item.entity';
import { OptionGroup } from '../../option-groups/entities/option-group.entity';
import { OptionChoice } from '../../option-groups/entities/option-choice.entity';
import { Ingredient } from '../../ingredients/entities/ingredient.entity';

@Entity('order_item_options')
export class OrderItemOption {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_item_id', type: 'uuid' })
  orderItemId: string;

  @ManyToOne(() => OrderItem, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'order_item_id' })
  orderItem: OrderItem;

  @Column({ name: 'option_group_id', type: 'uuid', nullable: true })
  optionGroupId?: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'option_group_id' })
  optionGroup?: OptionGroup;

  @Column({ name: 'option_choice_id', type: 'uuid', nullable: true })
  optionChoiceId?: string;

  @ManyToOne(() => OptionChoice, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'option_choice_id' })
  optionChoice?: OptionChoice;

  @Column({ name: 'ingredient_id', type: 'uuid', nullable: true })
  ingredientId?: string;

  @ManyToOne(() => Ingredient, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'ingredient_id' })
  ingredient?: Ingredient;

  @Column({ name: 'action', type: 'varchar', length: 20 })
  action: string;

  @Column({ name: 'option_name_snapshot', type: 'varchar', length: 140 })
  optionNameSnapshot: string;

  @Column({ name: 'quantity', type: 'numeric', precision: 8, scale: 2 })
  quantity: string;

  @Column({ name: 'unit_price_adjustment_minor', type: 'integer' })
  unitPriceAdjustmentMinor: number;

  @Column({ name: 'total_price_adjustment_minor', type: 'integer' })
  totalPriceAdjustmentMinor: number;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
