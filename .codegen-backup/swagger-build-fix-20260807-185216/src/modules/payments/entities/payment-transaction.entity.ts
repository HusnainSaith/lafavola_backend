import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { Order } from '../../orders/entities/order.entity';
import { User } from '../../users/entities/user.entity';
import { CustomerPaymentMethod } from './customer-payment-method.entity';

@Entity('payment_transactions')
export class PaymentTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_id', type: 'uuid' })
  orderId: string;

  @ManyToOne(() => Order, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({ name: 'customer_id', type: 'uuid', nullable: true })
  customerId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'customer_id' })
  customer?: User;

  @Column({ name: 'payment_method_id', type: 'uuid', nullable: true })
  paymentMethodId?: string;

  @ManyToOne(() => CustomerPaymentMethod, {
    onDelete: 'SET NULL',
    nullable: true,
  })
  @JoinColumn({ name: 'payment_method_id' })
  paymentMethod?: CustomerPaymentMethod;

  @Column({ name: 'provider', type: 'varchar', length: 40 })
  provider: string;

  @Column({ name: 'payment_method_type', type: 'varchar', length: 40 })
  paymentMethodType: string;

  @Column({
    name: 'provider_payment_intent_id',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  providerPaymentIntentId?: string;

  @Column({
    name: 'provider_charge_id',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  providerChargeId?: string;

  @Column({ name: 'amount_minor', type: 'integer' })
  amountMinor: number;

  @Column({ name: 'currency', type: 'char', length: 3 })
  currency: string;

  @Column({ name: 'status', type: 'varchar', length: 40 })
  status: string;

  @Column({
    name: 'idempotency_key',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  idempotencyKey?: string;

  @Column({
    name: 'failure_code',
    type: 'varchar',
    length: 120,
    nullable: true,
  })
  failureCode?: string;

  @Column({ name: 'failure_message', type: 'text', nullable: true })
  failureMessage?: string;

  @Column({ name: 'authorized_at', type: 'timestamptz', nullable: true })
  authorizedAt?: Date;

  @Column({ name: 'captured_at', type: 'timestamptz', nullable: true })
  capturedAt?: Date;

  @Column({ name: 'failed_at', type: 'timestamptz', nullable: true })
  failedAt?: Date;

  @Column({ name: 'metadata', type: 'jsonb' })
  metadata: Record<string, unknown>;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
