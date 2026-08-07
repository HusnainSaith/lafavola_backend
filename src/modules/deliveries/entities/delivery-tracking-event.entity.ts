import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { DeliveryTracking } from './delivery-tracking.entity';

@Entity('delivery_tracking_events')
export class DeliveryTrackingEvent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'tracking_id', type: 'uuid' })
  trackingId: string;

  @ManyToOne(() => DeliveryTracking, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'tracking_id' })
  tracking: DeliveryTracking;

  @Column({ name: 'status', type: 'varchar', length: 30, nullable: true })
  status?: string;

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

  @Column({ name: 'remaining_minutes', type: 'integer', nullable: true })
  remainingMinutes?: number;

  @Column({ name: 'source', type: 'varchar', length: 30 })
  source: string;

  @Column({ name: 'occurred_at', type: 'timestamptz' })
  occurredAt: Date;
}
