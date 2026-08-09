import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { MediaAsset } from '../../media/entities/media-asset.entity';
import { SupportMessage } from './support-message.entity';

@Entity('support_message_attachments')
export class SupportMessageAttachment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'support_message_id', type: 'uuid' })
  supportMessageId: string;

  @ManyToOne(() => SupportMessage, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'support_message_id' })
  supportMessage: SupportMessage;

  @Column({ name: 'media_asset_id', type: 'uuid' })
  mediaAssetId: string;

  @ManyToOne(() => MediaAsset, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'media_asset_id' })
  mediaAsset: MediaAsset;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
