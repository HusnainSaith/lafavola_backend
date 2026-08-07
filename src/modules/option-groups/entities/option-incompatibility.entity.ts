import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { OptionChoice } from './option-choice.entity';

@Entity('option_incompatibilities')
export class OptionIncompatibility {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'first_choice_id', type: 'uuid' })
  firstChoiceId: string;

  @ManyToOne(() => OptionChoice, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'first_choice_id' })
  firstChoice: OptionChoice;

  @Column({ name: 'second_choice_id', type: 'uuid' })
  secondChoiceId: string;

  @ManyToOne(() => OptionChoice, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'second_choice_id' })
  secondChoice: OptionChoice;

  @Column({ name: 'reason', type: 'varchar', length: 255, nullable: true })
  reason?: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
