import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { MenuCategory } from '../../categories/entities/menu-category.entity';
import { MenuItem } from '../../menu/entities/menu-item.entity';
import { Promotion } from './promotion.entity';

@Entity('promotion_items')
export class PromotionItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'promotion_id', type: 'uuid' })
  promotionId: string;

  @ManyToOne(() => Promotion, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'promotion_id' })
  promotion: Promotion;

  @Column({ name: 'menu_item_id', type: 'uuid', nullable: true })
  menuItemId?: string;

  @ManyToOne(() => MenuItem, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'menu_item_id' })
  menuItem?: MenuItem;

  @Column({ name: 'category_id', type: 'uuid', nullable: true })
  categoryId?: string;

  @ManyToOne(() => MenuCategory, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'category_id' })
  category?: MenuCategory;

  @Column({ name: 'eligibility_type', type: 'varchar', length: 20 })
  eligibilityType: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
