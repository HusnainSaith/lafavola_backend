import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('loyalty_accounts')
export class LoyaltyAccount {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'customer_id', type: 'uuid', unique: true })
  customerId: string;

  @OneToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'customer_id' })
  customer: User;

  @Column({ name: 'points_balance', type: 'integer' })
  pointsBalance: number;

  @Column({ name: 'lifetime_points_earned', type: 'integer' })
  lifetimePointsEarned: number;

  @Column({ name: 'tier', type: 'varchar', length: 40 })
  tier: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
