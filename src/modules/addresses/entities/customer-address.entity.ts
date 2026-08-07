import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('customer_addresses')
export class CustomerAddress {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'customer_id', type: 'uuid' })
  customerId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'customer_id' })
  customer: User;

  @Column({ name: 'label', type: 'varchar', length: 80, nullable: true })
  label?: string;

  @Column({
    name: 'recipient_name',
    type: 'varchar',
    length: 160,
    nullable: true,
  })
  recipientName?: string;

  @Column({ name: 'phone', type: 'varchar', length: 32, nullable: true })
  phone?: string;

  @Column({ name: 'address_line1', type: 'varchar', length: 255 })
  addressLine1: string;

  @Column({
    name: 'address_line2',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  addressLine2?: string;

  @Column({ name: 'city', type: 'varchar', length: 120 })
  city: string;

  @Column({ name: 'province', type: 'varchar', length: 120, nullable: true })
  province?: string;

  @Column({ name: 'postal_code', type: 'varchar', length: 24 })
  postalCode: string;

  @Column({ name: 'country_code', type: 'char', length: 2 })
  countryCode: string;

  @Column({
    name: 'latitude',
    type: 'numeric',
    precision: 9,
    scale: 6,
    nullable: true,
  })
  latitude?: string;

  @Column({
    name: 'longitude',
    type: 'numeric',
    precision: 9,
    scale: 6,
    nullable: true,
  })
  longitude?: string;

  @Column({ name: 'delivery_instructions', type: 'text', nullable: true })
  deliveryInstructions?: string;

  @Column({ name: 'is_default', type: 'boolean' })
  isDefault: boolean;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
