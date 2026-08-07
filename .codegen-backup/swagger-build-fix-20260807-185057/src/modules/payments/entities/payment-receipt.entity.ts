import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { Order } from '../../orders/entities/order.entity';
import { PaymentTransaction } from './payment-transaction.entity';

@Entity('payment_receipts')
export class PaymentReceipt {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_id', type: 'uuid' })
  orderId: string;

  @ManyToOne(() => Order, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({ name: 'payment_transaction_id', type: 'uuid', nullable: true })
  paymentTransactionId?: string;

  @ManyToOne(() => PaymentTransaction, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'payment_transaction_id' })
  paymentTransaction?: PaymentTransaction;

  @Column({ name: 'receipt_number', type: 'varchar', length: 80, unique: true })
  receiptNumber: string;

  @Column({ name: 'issued_at', type: 'timestamptz' })
  issuedAt: Date;

  @Column({ name: 'amount_minor', type: 'integer' })
  amountMinor: number;

  @Column({ name: 'tax_minor', type: 'integer' })
  taxMinor: number;

  @Column({ name: 'currency', type: 'char', length: 3 })
  currency: string;

  @Column({ name: 'provider_receipt_url', type: 'text', nullable: true })
  providerReceiptUrl?: string;

  @Column({ name: 'receipt_data', type: 'jsonb' })
  receiptData: Record<string, unknown>;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
