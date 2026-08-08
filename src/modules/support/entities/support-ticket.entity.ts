import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Order } from '../../orders/entities/order.entity';
import { User } from '../../users/entities/user.entity';

@Entity('support_tickets')
export class SupportTicket {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'customer_id', type: 'uuid', nullable: true })
  customerId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'customer_id' })
  customer?: User;

  @Column({ name: 'order_id', type: 'uuid', nullable: true })
  orderId?: string;

  @ManyToOne(() => Order, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'order_id' })
  order?: Order;

  @Column({ name: 'assigned_staff_user_id', type: 'uuid', nullable: true })
  assignedStaffUserId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'assigned_staff_user_id' })
  assignedStaffUser?: User;

  @Column({ name: 'assigned_at', type: 'timestamptz', nullable: true })
  assignedAt?: Date;

  @Column({ name: 'last_message_at', type: 'timestamptz', nullable: true })
  lastMessageAt?: Date;

  @Column({
    name: 'customer_last_read_at',
    type: 'timestamptz',
    nullable: true,
  })
  customerLastReadAt?: Date;

  @Column({ name: 'staff_last_read_at', type: 'timestamptz', nullable: true })
  staffLastReadAt?: Date;

  @Column({ name: 'customer_unread_count', type: 'integer' })
  customerUnreadCount: number;

  @Column({ name: 'staff_unread_count', type: 'integer' })
  staffUnreadCount: number;

  @Column({ name: 'category', type: 'varchar', length: 30 })
  category: string;

  @Column({ name: 'subject', type: 'varchar', length: 200 })
  subject: string;

  @Column({ name: 'status', type: 'varchar', length: 30 })
  status: string;

  @Column({ name: 'priority', type: 'varchar', length: 20 })
  priority: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @Column({ name: 'resolved_at', type: 'timestamptz', nullable: true })
  resolvedAt?: Date;

  @Column({ name: 'closed_at', type: 'timestamptz', nullable: true })
  closedAt?: Date;
}
