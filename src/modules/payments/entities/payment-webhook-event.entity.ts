import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('payment_webhook_events')
export class PaymentWebhookEvent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'provider', type: 'varchar', length: 30 })
  provider: string;

  @Column({ name: 'provider_event_id', type: 'varchar', length: 255 })
  providerEventId: string;

  @Column({ name: 'event_type', type: 'varchar', length: 160 })
  eventType: string;

  @Column({ name: 'payload', type: 'jsonb' })
  payload: Record<string, unknown>;

  @Column({ name: 'processing_status', type: 'varchar', length: 30 })
  processingStatus: string;

  @Column({ name: 'attempts', type: 'integer' })
  attempts: number;

  @Column({ name: 'processed_at', type: 'timestamptz', nullable: true })
  processedAt?: Date;

  @Column({ name: 'last_error', type: 'text', nullable: true })
  lastError?: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
