import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('idempotency_keys')
export class IdempotencyKey {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'actor_user_id', type: 'uuid', nullable: true })
  actorUserId?: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'actor_user_id' })
  actorUser?: User;

  @Column({ name: 'scope', type: 'varchar', length: 120 })
  scope: string;

  @Column({ name: 'key_hash', type: 'varchar', length: 128 })
  keyHash: string;

  @Column({
    name: 'request_hash',
    type: 'varchar',
    length: 128,
    nullable: true,
  })
  requestHash?: string;

  @Column({ name: 'response_status', type: 'integer', nullable: true })
  responseStatus?: number;

  @Column({ name: 'response_body', type: 'jsonb', nullable: true })
  responseBody?: Record<string, unknown>;

  @Column({ name: 'locked_until', type: 'timestamptz', nullable: true })
  lockedUntil?: Date;

  @Column({ name: 'expires_at', type: 'timestamptz' })
  expiresAt: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
