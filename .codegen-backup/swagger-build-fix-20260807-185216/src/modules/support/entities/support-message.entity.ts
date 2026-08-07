import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { SupportTicket } from './support-ticket.entity';
import { User } from '../../users/entities/user.entity';

@Entity('support_messages')
export class SupportMessage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'ticket_id', type: 'uuid' })
  ticketId: string;

  @ManyToOne(() => SupportTicket, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'ticket_id' })
  ticket: SupportTicket;

  @Column({ name: 'author_user_id', type: 'uuid', nullable: true })
  authorUserId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'author_user_id' })
  authorUser?: User;

  @Column({ name: 'author_type', type: 'varchar', length: 20 })
  authorType: string;

  @Column({ name: 'body', type: 'text' })
  body: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
