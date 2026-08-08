import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Order } from '../../orders/entities/order.entity';
import { DeliveryAssignment } from './delivery-assignment.entity';

@Entity('delivery_tracking')
export class DeliveryTracking {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_id', type: 'uuid', unique: true })
  orderId: string;

  @OneToOne(() => Order, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({ name: 'assignment_id', type: 'uuid', nullable: true })
  assignmentId?: string;

  @ManyToOne(() => DeliveryAssignment, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'assignment_id' })
  assignment?: DeliveryAssignment;

  @Column({ name: 'status', type: 'varchar', length: 30 })
  status: string;

  @Column({
    name: 'current_latitude',
    type: 'numeric',
    precision: 9,
    scale: 6,
    nullable: true,
  })
  currentLatitude?: string;

  @Column({
    name: 'current_longitude',
    type: 'numeric',
    precision: 9,
    scale: 6,
    nullable: true,
  })
  currentLongitude?: string;

  @Column({
    name: 'heading_degrees',
    type: 'numeric',
    precision: 6,
    scale: 2,
    nullable: true,
  })
  headingDegrees?: string;

  @Column({
    name: 'speed_kph',
    type: 'numeric',
    precision: 7,
    scale: 2,
    nullable: true,
  })
  speedKph?: string;

  @Column({ name: 'remaining_minutes', type: 'integer', nullable: true })
  remainingMinutes?: number;

  @Column({ name: 'estimated_arrival_at', type: 'timestamptz', nullable: true })
  estimatedArrivalAt?: Date;

  @Column({ name: 'last_pinged_at', type: 'timestamptz', nullable: true })
  lastPingedAt?: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
