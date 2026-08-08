import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Ingredient } from '../../ingredients/entities/ingredient.entity';
import { MenuItem } from './menu-item.entity';

@Entity('menu_item_ingredients')
export class MenuItemIngredient {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'menu_item_id', type: 'uuid' })
  menuItemId: string;

  @ManyToOne(() => MenuItem, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem: MenuItem;

  @Column({ name: 'ingredient_id', type: 'uuid' })
  ingredientId: string;

  @ManyToOne(() => Ingredient, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'ingredient_id' })
  ingredient: Ingredient;

  @Column({ name: 'is_default', type: 'boolean' })
  isDefault: boolean;

  @Column({ name: 'is_removable', type: 'boolean' })
  isRemovable: boolean;

  @Column({ name: 'default_quantity', type: 'numeric', precision: 8, scale: 2 })
  defaultQuantity: string;

  @Column({ name: 'display_order', type: 'integer' })
  displayOrder: number;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
