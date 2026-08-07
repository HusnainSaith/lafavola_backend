import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { Order } from '../../orders/entities/order.entity';
import { PaymentTransaction } from '../../payments/entities/payment-transaction.entity';
import { User } from '../../users/entities/user.entity';

@Entity('refunds')
export class Refund {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_id', type: 'uuid' })
  orderId: string;

  @ManyToOne(() => Order, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({ name: 'payment_transaction_id', type: 'uuid', nullable: true })
  paymentTransactionId?: string;

  @ManyToOne(() => PaymentTransaction, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'payment_transaction_id' })
  paymentTransaction?: PaymentTransaction;

  @Column({ name: 'requested_by_user_id', type: 'uuid', nullable: true })
  requestedByUserId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'requested_by_user_id' })
  requestedByUser?: User;

  @Column({
    name: 'provider_refund_id',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  providerRefundId?: string;

  @Column({ name: 'amount_minor', type: 'integer' })
  amountMinor: number;

  @Column({ name: 'reason', type: 'varchar', length: 80 })
  reason: string;

  @Column({ name: 'customer_reason', type: 'text', nullable: true })
  customerReason?: string;

  @Column({ name: 'status', type: 'varchar', length: 30 })
  status: string;

  @Column({ name: 'staff_note', type: 'text', nullable: true })
  staffNote?: string;

  @Column({ name: 'requested_at', type: 'timestamptz' })
  requestedAt: Date;

  @Column({ name: 'processed_at', type: 'timestamptz', nullable: true })
  processedAt?: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
