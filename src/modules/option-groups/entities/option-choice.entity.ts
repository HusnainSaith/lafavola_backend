import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Ingredient } from '../../ingredients/entities/ingredient.entity';
import { OptionGroup } from './option-group.entity';

@Entity('option_choices')
export class OptionChoice {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'option_group_id', type: 'uuid' })
  optionGroupId: string;

  @ManyToOne(() => OptionGroup, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'option_group_id' })
  optionGroup: OptionGroup;

  @Column({ name: 'ingredient_id', type: 'uuid', nullable: true })
  ingredientId?: string;

  @ManyToOne(() => Ingredient, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'ingredient_id' })
  ingredient?: Ingredient;

  @Column({ name: 'name', type: 'varchar', length: 140 })
  name: string;

  @Column({ name: 'code', type: 'varchar', length: 120 })
  code: string;

  @Column({ name: 'price_adjustment_minor', type: 'integer' })
  priceAdjustmentMinor: number;

  @Column({ name: 'calories_adjustment', type: 'integer' })
  caloriesAdjustment: number;

  @Column({ name: 'is_default', type: 'boolean' })
  isDefault: boolean;

  @Column({ name: 'display_order', type: 'integer' })
  displayOrder: number;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
