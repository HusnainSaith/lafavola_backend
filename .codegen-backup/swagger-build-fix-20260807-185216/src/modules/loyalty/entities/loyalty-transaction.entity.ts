import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { LoyaltyAccount } from './loyalty-account.entity';
import { Order } from '../../orders/entities/order.entity';
import { User } from '../../users/entities/user.entity';

@Entity('loyalty_transactions')
export class LoyaltyTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'loyalty_account_id', type: 'uuid' })
  loyaltyAccountId: string;

  @ManyToOne(() => LoyaltyAccount, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'loyalty_account_id' })
  loyaltyAccount: LoyaltyAccount;

  @Column({ name: 'order_id', type: 'uuid', nullable: true })
  orderId?: string;

  @ManyToOne(() => Order, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'order_id' })
  order?: Order;

  @Column({ name: 'type', type: 'varchar', length: 30 })
  type: string;

  @Column({ name: 'points_delta', type: 'integer' })
  pointsDelta: number;

  @Column({ name: 'balance_after', type: 'integer' })
  balanceAfter: number;

  @Column({ name: 'description', type: 'varchar', length: 255, nullable: true })
  description?: string;

  @Column({ name: 'expires_at', type: 'timestamptz', nullable: true })
  expiresAt?: Date;

  @Column({ name: 'created_by_user_id', type: 'uuid', nullable: true })
  createdByUserId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'created_by_user_id' })
  createdByUser?: User;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
