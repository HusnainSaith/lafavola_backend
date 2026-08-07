import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('customer_payment_methods')
export class CustomerPaymentMethod {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'customer_id', type: 'uuid' })
  customerId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'customer_id' })
  customer: User;

  @Column({ name: 'provider', type: 'varchar', length: 30 })
  provider: string;

  @Column({
    name: 'provider_customer_id',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  providerCustomerId?: string;

  @Column({
    name: 'provider_payment_method_id',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  providerPaymentMethodId?: string;

  @Column({ name: 'payment_method_type', type: 'varchar', length: 40 })
  paymentMethodType: string;

  @Column({ name: 'card_brand', type: 'varchar', length: 40, nullable: true })
  cardBrand?: string;

  @Column({ name: 'card_last4', type: 'char', length: 4, nullable: true })
  cardLast4?: string;

  @Column({ name: 'exp_month', type: 'smallint', nullable: true })
  expMonth?: number;

  @Column({ name: 'exp_year', type: 'smallint', nullable: true })
  expYear?: number;

  @Column({ name: 'label', type: 'varchar', length: 80, nullable: true })
  label?: string;

  @Column({ name: 'is_default', type: 'boolean' })
  isDefault: boolean;

  @Column({ name: 'archived_at', type: 'timestamptz', nullable: true })
  archivedAt?: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
