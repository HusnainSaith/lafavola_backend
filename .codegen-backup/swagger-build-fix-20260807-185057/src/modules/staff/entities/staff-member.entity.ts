import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';

@Entity('staff_members')
export class StaffMember {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid', unique: true })
  userId: string;

  @OneToOne(() => User, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'restaurant_id', type: 'uuid' })
  restaurantId: string;

  @ManyToOne(() => Restaurant, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'restaurant_id' })
  restaurant: Restaurant;

  @Column({
    name: 'employee_code',
    type: 'varchar',
    length: 80,
    nullable: true,
  })
  employeeCode?: string;

  @Column({ name: 'job_title', type: 'varchar', length: 120, nullable: true })
  jobTitle?: string;

  @Column({ name: 'is_active', type: 'boolean' })
  isActive: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
