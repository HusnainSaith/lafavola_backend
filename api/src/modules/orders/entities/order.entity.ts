import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Cart } from '../../carts/entities/cart.entity';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { User } from '../../users/entities/user.entity';

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_number', type: 'varchar', length: 40, unique: true })
  orderNumber: string;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({ name: 'customer_id', type: 'uuid', nullable: true })
  customerId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'customer_id' })
  customer?: User;

  @Column({ name: 'cart_id', type: 'uuid', nullable: true })
  cartId?: string;

  @ManyToOne(() => Cart, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'cart_id' })
  cart?: Cart;

  @Column({ name: 'order_type', type: 'varchar', length: 20 })
  orderType: string;

  @Column({ name: 'status', type: 'varchar', length: 40 })
  status: string;

  @Column({ name: 'payment_status', type: 'varchar', length: 40 })
  paymentStatus: string;

  @Column({
    name: 'payment_method',
    type: 'varchar',
    length: 40,
    nullable: true,
  })
  paymentMethod?: string;

  @Column({ name: 'currency', type: 'char', length: 3 })
  currency: string;

  @Column({ name: 'subtotal_minor', type: 'integer' })
  subtotalMinor: number;

  @Column({ name: 'option_charges_minor', type: 'integer' })
  optionChargesMinor: number;

  @Column({ name: 'discount_minor', type: 'integer' })
  discountMinor: number;

  @Column({ name: 'promotion_discount_minor', type: 'integer' })
  promotionDiscountMinor: number;

  @Column({ name: 'coupon_discount_minor', type: 'integer' })
  couponDiscountMinor: number;

  @Column({ name: 'loyalty_discount_minor', type: 'integer' })
  loyaltyDiscountMinor: number;

  @Column({ name: 'delivery_fee_minor', type: 'integer' })
  deliveryFeeMinor: number;

  @Column({ name: 'tax_minor', type: 'integer' })
  taxMinor: number;

  @Column({ name: 'grand_total_minor', type: 'integer' })
  grandTotalMinor: number;

  @Column({ name: 'delivery_address_snapshot', type: 'jsonb', nullable: true })
  deliveryAddressSnapshot?: Record<string, unknown>;

  @Column({ name: 'delivery_instructions', type: 'text', nullable: true })
  deliveryInstructions?: string;

  @Column({ name: 'customer_note', type: 'text', nullable: true })
  customerNote?: string;

  @Column({ name: 'table_label', type: 'varchar', length: 40, nullable: true })
  tableLabel?: string;

  @Column({
    name: 'walk_in_customer_name',
    type: 'varchar',
    length: 120,
    nullable: true,
  })
  walkInCustomerName?: string;

  @Column({
    name: 'walk_in_customer_phone',
    type: 'varchar',
    length: 32,
    nullable: true,
  })
  walkInCustomerPhone?: string;

  @Column({ name: 'created_by_staff_user_id', type: 'uuid', nullable: true })
  createdByStaffUserId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'created_by_staff_user_id' })
  createdByStaffUser?: User;

  @Column({
    name: 'estimated_delivery_at',
    type: 'timestamptz',
    nullable: true,
  })
  estimatedDeliveryAt?: Date;

  @Column({ name: 'estimated_ready_at', type: 'timestamptz', nullable: true })
  estimatedReadyAt?: Date;

  @Column({ name: 'scheduled_for', type: 'timestamptz', nullable: true })
  scheduledFor?: Date;

  @Column({ name: 'placed_at', type: 'timestamptz', nullable: true })
  placedAt?: Date;

  @Column({ name: 'accepted_at', type: 'timestamptz', nullable: true })
  acceptedAt?: Date;

  @Column({ name: 'delivered_at', type: 'timestamptz', nullable: true })
  deliveredAt?: Date;

  @Column({ name: 'cancelled_at', type: 'timestamptz', nullable: true })
  cancelledAt?: Date;

  @Column({ name: 'cancellation_reason', type: 'text', nullable: true })
  cancellationReason?: string;

  @Column({ name: 'pricing_snapshot', type: 'jsonb' })
  pricingSnapshot: Record<string, unknown>;

  @Column({ name: 'version', type: 'bigint' })
  version: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
