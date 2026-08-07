import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { MenuCategory } from '../../categories/entities/menu-category.entity';
import { MediaAsset } from '../../media/entities/media-asset.entity';

@Entity('menu_items')
export class MenuItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'category_id', type: 'uuid', nullable: true })
  categoryId?: string;

  @ManyToOne(() => MenuCategory, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'category_id' })
  category?: MenuCategory;

  @Column({ name: 'name', type: 'varchar', length: 180 })
  name: string;

  @Column({ name: 'slug', type: 'varchar', length: 200 })
  slug: string;

  @Column({ name: 'description', type: 'text', nullable: true })
  description?: string;

  @Column({ name: 'image_asset_id', type: 'uuid', nullable: true })
  imageAssetId?: string;

  @ManyToOne(() => MediaAsset, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'image_asset_id' })
  imageAsset?: MediaAsset;

  @Column({ name: 'item_type', type: 'varchar', length: 30 })
  itemType: string;

  @Column({ name: 'calories', type: 'integer', nullable: true })
  calories?: number;

  @Column({ name: 'preparation_minutes', type: 'integer' })
  preparationMinutes: number;

  @Column({ name: 'is_vegetarian', type: 'boolean' })
  isVegetarian: boolean;

  @Column({ name: 'is_vegan', type: 'boolean' })
  isVegan: boolean;

  @Column({ name: 'is_gluten_free', type: 'boolean' })
  isGlutenFree: boolean;

  @Column({ name: 'is_spicy', type: 'boolean' })
  isSpicy: boolean;

  @Column({ name: 'is_popular', type: 'boolean' })
  isPopular: boolean;

  @Column({
    name: 'popularity_score',
    type: 'numeric',
    precision: 12,
    scale: 4,
  })
  popularityScore: string;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'available_from', type: 'timestamptz', nullable: true })
  availableFrom?: Date;

  @Column({ name: 'available_until', type: 'timestamptz', nullable: true })
  availableUntil?: Date;

  @Column({ name: 'archived_at', type: 'timestamptz', nullable: true })
  archivedAt?: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
