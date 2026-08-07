import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('customer_preferences')
export class CustomerPreference {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'customer_id', type: 'uuid', unique: true })
  customerId: string;

  @OneToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'customer_id' })
  customer: User;

  @Column({ name: 'vegetarian_preference', type: 'boolean' })
  vegetarianPreference: boolean;

  @Column({ name: 'vegan_preference', type: 'boolean' })
  veganPreference: boolean;

  @Column({ name: 'gluten_free_preference', type: 'boolean' })
  glutenFreePreference: boolean;

  @Column({ name: 'spicy_preference', type: 'boolean' })
  spicyPreference: boolean;

  @Column({ name: 'default_payment_method_id', type: 'uuid', nullable: true })
  defaultPaymentMethodId?: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
