import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';

@Entity('option_groups')
export class OptionGroup {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'name', type: 'varchar', length: 140 })
  name: string;

  @Column({ name: 'code', type: 'varchar', length: 100 })
  code: string;

  @Column({ name: 'option_type', type: 'varchar', length: 30 })
  optionType: string;

  @Column({ name: 'min_select', type: 'integer' })
  minSelect: number;

  @Column({ name: 'max_select', type: 'integer', nullable: true })
  maxSelect?: number;

  @Column({ name: 'is_required', type: 'boolean' })
  isRequired: boolean;

  @Column({ name: 'allow_quantity', type: 'boolean' })
  allowQuantity: boolean;

  @Column({ name: 'display_order', type: 'integer' })
  displayOrder: number;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
