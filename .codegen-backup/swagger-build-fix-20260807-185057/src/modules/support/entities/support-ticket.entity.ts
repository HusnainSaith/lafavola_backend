import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Order } from '../../orders/entities/order.entity';

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
