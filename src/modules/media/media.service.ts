import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { DataSource } from 'typeorm';
import {
  STORAGE_PROVIDER,
  StorageProvider,
} from '../../integrations/storage/storage.interface';
import { MenuItem } from '../menu/entities/menu-item.entity';
import { SupportTicket } from '../support/entities/support-ticket.entity';
import { User } from '../users/entities/user.entity';
import { CreateUploadUrlDto, MediaPurpose } from './dto/create-upload-url.dto';
import { FinalizeUploadDto } from './dto/finalize-upload.dto';
import { MediaAssetRepository } from './repositories/media-asset.repository';

const MIME: Record<string, { extension: string; maxBytes: number }> = {
  'image/jpeg': { extension: 'jpg', maxBytes: 5 * 1024 * 1024 },
  'image/png': { extension: 'png', maxBytes: 5 * 1024 * 1024 },
  'image/webp': { extension: 'webp', maxBytes: 5 * 1024 * 1024 },
  'application/pdf': { extension: 'pdf', maxBytes: 10 * 1024 * 1024 },
};

@Injectable()
export class MediaService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly assets: MediaAssetRepository,
    @Inject(STORAGE_PROVIDER) private readonly storage: StorageProvider,
  ) {}

  async authorizeUpload(userId: string, dto: CreateUploadUrlDto) {
    const format = MIME[dto.mimeType];
    const imageOnly = [MediaPurpose.MENU_IMAGE, MediaPurpose.AVATAR].includes(
      dto.purpose,
    );
    if (!format || (imageOnly && dto.mimeType === 'application/pdf'))
      throw new BadRequestException(
        'File type is not allowed for this purpose',
      );
    if (dto.sizeBytes > format.maxBytes)
      throw new BadRequestException('File exceeds the allowed size');
    await this.assertTargetAccess(userId, dto);

    const objectKey = this.buildKey(userId, dto, format.extension);
    const expiresInSeconds = 300;
    const uploadUrl = await this.storage.presignPut({
      key: objectKey,
      contentType: dto.mimeType,
      contentLength: dto.sizeBytes,
      expiresInSeconds,
    });
    const asset = await this.assets.save(
      this.assets.create({
        restaurantId: dto.restaurantId,
        uploadedByUserId: userId,
        storageProvider: this.storage.providerName,
        bucket: this.storage.bucket,
        objectKey,
        originalFileName: dto.fileName,
        purpose: dto.purpose,
        targetId: dto.targetId,
        mimeType: dto.mimeType,
        sizeBytes: String(dto.sizeBytes),
        altText: dto.altText,
        status: 'pending',
      }),
    );
    return {
      assetId: asset.id,
      uploadUrl,
      expiresInSeconds,
      method: 'PUT' as const,
      requiredHeaders: {
        'Content-Type': dto.mimeType,
        'Content-Length': String(dto.sizeBytes),
      },
    };
  }

  async finalize(userId: string, assetId: string, dto: FinalizeUploadDto) {
    const asset = await this.ownedPendingAsset(userId, assetId);
    const metadata = await this.storage.head(asset.objectKey);
    if (
      metadata.contentType !== asset.mimeType ||
      metadata.contentLength !== Number(asset.sizeBytes)
    ) {
      throw new BadRequestException('Uploaded object metadata does not match');
    }
    asset.status = 'active';
    asset.width = dto.width;
    asset.height = dto.height;
    if (asset.purpose === MediaPurpose.MENU_IMAGE) {
      asset.publicUrl = this.storage.publicUrl(asset.objectKey);
    }
    return this.assets.save(asset);
  }

  async remove(userId: string, assetId: string): Promise<void> {
    const asset = await this.assets.findOne({ where: { id: assetId } });
    if (!asset) throw new NotFoundException('Media asset not found');
    if (asset.uploadedByUserId !== userId)
      throw new NotFoundException('Media asset not found');
    await this.storage.delete(asset.objectKey);
    asset.status = 'deleted';
    asset.publicUrl = undefined;
    await this.assets.save(asset);
  }

  private async ownedPendingAsset(userId: string, assetId: string) {
    const asset = await this.assets.findOne({
      where: { id: assetId, uploadedByUserId: userId, status: 'pending' },
    });
    if (!asset) throw new NotFoundException('Pending media asset not found');
    return asset;
  }

  private buildKey(userId: string, dto: CreateUploadUrlDto, extension: string) {
    const id = randomUUID();
    if (dto.purpose === MediaPurpose.MENU_IMAGE)
      return `restaurants/${dto.restaurantId}/menu/${id}.${extension}`;
    if (dto.purpose === MediaPurpose.AVATAR)
      return `customers/${userId}/avatars/${id}.${extension}`;
    return `support/${dto.targetId}/${id}.${extension}`;
  }

  private async assertTargetAccess(userId: string, dto: CreateUploadUrlDto) {
    if (dto.purpose === MediaPurpose.AVATAR) return;
    if (dto.purpose === MediaPurpose.MENU_IMAGE) {
      if (!dto.restaurantId || !dto.targetId)
        throw new BadRequestException('Restaurant and menu item are required');
      const item = await this.dataSource.getRepository(MenuItem).findOne({
        where: { id: dto.targetId, restaurantId: dto.restaurantId },
      });
      if (!item) throw new NotFoundException('Menu item not found');
      const user = await this.dataSource.getRepository(User).findOne({
        where: { id: userId },
        relations: { role: true },
      });
      const staff = await this.dataSource.query(
        `SELECT 1 FROM staff_members
         WHERE user_id=$1 AND restaurant_id=$2 AND is_active=true LIMIT 1`,
        [userId, dto.restaurantId],
      );
      if (user?.role?.name !== 'admin' && !staff.length)
        throw new ForbiddenException('Not allowed to manage this menu');
      return;
    }
    if (!dto.targetId)
      throw new BadRequestException('Support ticket is required');
    const ticket = await this.dataSource.getRepository(SupportTicket).findOne({
      where: { id: dto.targetId },
    });
    if (
      !ticket ||
      (ticket.customerId !== userId && ticket.assignedStaffUserId !== userId)
    )
      throw new NotFoundException('Support ticket not found');
  }
}
