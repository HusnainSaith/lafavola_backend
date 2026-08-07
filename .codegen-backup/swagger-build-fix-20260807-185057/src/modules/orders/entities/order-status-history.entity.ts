import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { Order } from './order.entity';
import { User } from '../../users/entities/user.entity';

@Entity('order_status_history')
export class OrderStatusHistory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'order_id', type: 'uuid' })
  orderId: string;

  @ManyToOne(() => Order, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({
    name: 'previous_status',
    type: 'varchar',
    length: 40,
    nullable: true,
  })
  previousStatus?: string;

  @Column({ name: 'new_status', type: 'varchar', length: 40 })
  newStatus: string;

  @Column({ name: 'changed_by_user_id', type: 'uuid', nullable: true })
  changedByUserId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'changed_by_user_id' })
  changedByUser?: User;

  @Column({ name: 'note', type: 'text', nullable: true })
  note?: string;

  @Column({ name: 'occurred_at', type: 'timestamptz' })
  occurredAt: Date;
}
