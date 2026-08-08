import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { MediaAsset } from '../../media/entities/media-asset.entity';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { IngredientCategory } from './ingredient-category.entity';

@Entity('ingredients')
export class Ingredient {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'category_id', type: 'uuid', nullable: true })
  categoryId?: string;

  @ManyToOne(() => IngredientCategory, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'category_id' })
  category?: IngredientCategory;

  @Column({ name: 'name', type: 'varchar', length: 140 })
  name: string;

  @Column({ name: 'slug', type: 'varchar', length: 160 })
  slug: string;

  @Column({ name: 'description', type: 'text', nullable: true })
  description?: string;

  @Column({ name: 'image_asset_id', type: 'uuid', nullable: true })
  imageAssetId?: string;

  @ManyToOne(() => MediaAsset, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'image_asset_id' })
  imageAsset?: MediaAsset;

  @Column({ name: 'extra_price_minor', type: 'integer' })
  extraPriceMinor: number;

  @Column({ name: 'calories', type: 'integer', nullable: true })
  calories?: number;

  @Column({ name: 'is_vegetarian', type: 'boolean' })
  isVegetarian: boolean;

  @Column({ name: 'is_vegan', type: 'boolean' })
  isVegan: boolean;

  @Column({ name: 'is_gluten_free', type: 'boolean' })
  isGlutenFree: boolean;

  @Column({ name: 'is_spicy', type: 'boolean' })
  isSpicy: boolean;

  @Column({ name: 'contains_allergens', type: 'text', array: true })
  containsAllergens: string[];

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
