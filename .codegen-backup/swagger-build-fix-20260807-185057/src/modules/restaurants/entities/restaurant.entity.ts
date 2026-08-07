import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('restaurants')
export class Restaurant {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'name', type: 'varchar', length: 160 })
  name: string;

  @Column({ name: 'slug', type: 'varchar', length: 180, unique: true })
  slug: string;

  @Column({ name: 'phone', type: 'varchar', length: 32, nullable: true })
  phone?: string;

  @Column({ name: 'email', type: 'varchar', length: 320, nullable: true })
  email?: string;

  @Column({
    name: 'address_line1',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  addressLine1?: string;

  @Column({
    name: 'address_line2',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  addressLine2?: string;

  @Column({ name: 'city', type: 'varchar', length: 120, nullable: true })
  city?: string;

  @Column({ name: 'province', type: 'varchar', length: 120, nullable: true })
  province?: string;

  @Column({ name: 'postal_code', type: 'varchar', length: 24, nullable: true })
  postalCode?: string;

  @Column({ name: 'country_code', type: 'char', length: 2 })
  countryCode: string;

  @Column({ name: 'currency', type: 'char', length: 3 })
  currency: string;

  @Column({ name: 'timezone', type: 'varchar', length: 80 })
  timezone: string;

  @Column({ name: 'default_delivery_minutes', type: 'integer' })
  defaultDeliveryMinutes: number;

  @Column({ name: 'delivery_fee_minor', type: 'integer' })
  deliveryFeeMinor: number;

  @Column({ name: 'minimum_order_minor', type: 'integer' })
  minimumOrderMinor: number;

  @Column({ name: 'tax_rate_basis_points', type: 'integer' })
  taxRateBasisPoints: number;

  @Column({ name: 'tax_behavior', type: 'varchar', length: 20 })
  taxBehavior: string;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
