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
import { MenuCategory } from '../categories/entities/menu-category.entity';
import { CustomerProfile } from '../customers/entities/customer-profile.entity';
import { Ingredient } from '../ingredients/entities/ingredient.entity';
import { SupportTicket } from '../support/entities/support-ticket.entity';
import { User } from '../users/entities/user.entity';
import {
  CreateUploadUrlDto,
  MediaPurpose,
  MultipartUploadDto,
} from './dto/create-upload-url.dto';
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

  async upload(
    userId: string,
    file: Express.Multer.File,
    dto: MultipartUploadDto,
  ) {
    if (!file) throw new BadRequestException('File is required');
    const format = MIME[file.mimetype];
    const imagePurpose = dto.purpose !== MediaPurpose.SUPPORT_ATTACHMENT;
    if (!format || (imagePurpose && file.mimetype === 'application/pdf'))
      throw new BadRequestException(
        'File type is not allowed for this purpose',
      );
    if (file.size > format.maxBytes)
      throw new BadRequestException('File exceeds the allowed size');
    const authorization = {
      ...dto,
      fileName: file.originalname,
      mimeType: file.mimetype,
      sizeBytes: file.size,
    } as CreateUploadUrlDto;
    await this.assertTargetAccess(userId, authorization);
    const objectKey = this.buildKey(userId, authorization, format.extension);
    await this.storage.put({
      key: objectKey,
      contentType: file.mimetype,
      body: file.buffer,
    });
    try {
      const asset = await this.assets.save(
        this.assets.create({
          restaurantId: dto.restaurantId,
          uploadedByUserId: userId,
          storageProvider: this.storage.providerName,
          bucket: this.storage.bucket,
          objectKey,
          originalFileName: file.originalname,
          purpose: dto.purpose,
          targetId: dto.targetId,
          publicUrl: this.storage.publicUrl(objectKey),
          mimeType: file.mimetype,
          sizeBytes: String(file.size),
          altText: dto.altText,
          status: 'active',
        }),
      );
      await this.attachUploadedAsset(userId, asset.id, asset.publicUrl, dto);
      return asset;
    } catch (error) {
      await this.storage.delete(objectKey);
      throw error;
    }
  }

  private async attachUploadedAsset(
    userId: string,
    assetId: string,
    publicUrl: string | undefined,
    dto: MultipartUploadDto,
  ): Promise<void> {
    if (dto.purpose === MediaPurpose.AVATAR) {
      if (!publicUrl)
        throw new BadRequestException(
          'AWS_S3_PUBLIC_BASE_URL is required for avatar uploads',
        );
      const profiles = this.dataSource.getRepository(CustomerProfile);
      let profile = await profiles.findOne({ where: { userId } });
      profile = profile
        ? Object.assign(profile, { avatarUrl: publicUrl })
        : profiles.create({
            userId,
            avatarUrl: publicUrl,
            preferredLanguage: 'it',
            loyaltyOptIn: false,
            marketingOptIn: false,
          });
      await profiles.save(profile);
      return;
    }
    if (!dto.targetId) return;
    if (dto.purpose === MediaPurpose.MENU_IMAGE)
      await this.dataSource
        .getRepository(MenuItem)
        .update(dto.targetId, { imageAssetId: assetId });
    if (dto.purpose === MediaPurpose.CATEGORY_IMAGE)
      await this.dataSource
        .getRepository(MenuCategory)
        .update(dto.targetId, { imageAssetId: assetId });
    if (dto.purpose === MediaPurpose.INGREDIENT_IMAGE)
      await this.dataSource
        .getRepository(Ingredient)
        .update(dto.targetId, { imageAssetId: assetId });
  }

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
    if (dto.purpose === MediaPurpose.CATEGORY_IMAGE)
      return `restaurants/${dto.restaurantId}/categories/${id}.${extension}`;
    if (dto.purpose === MediaPurpose.INGREDIENT_IMAGE)
      return `restaurants/${dto.restaurantId}/ingredients/${id}.${extension}`;
    if (dto.purpose === MediaPurpose.AVATAR)
      return `customers/${userId}/avatars/${id}.${extension}`;
    return `support/${dto.targetId}/${id}.${extension}`;
  }

  private async assertTargetAccess(userId: string, dto: CreateUploadUrlDto) {
    if (dto.purpose === MediaPurpose.AVATAR) return;
    if (
      [
        MediaPurpose.MENU_IMAGE,
        MediaPurpose.CATEGORY_IMAGE,
        MediaPurpose.INGREDIENT_IMAGE,
      ].includes(dto.purpose)
    ) {
      if (!dto.restaurantId || !dto.targetId)
        throw new BadRequestException('Restaurant and menu item are required');
      const entity =
        dto.purpose === MediaPurpose.MENU_IMAGE
          ? await this.dataSource.getRepository(MenuItem).findOne({
              where: { id: dto.targetId, restaurantId: dto.restaurantId },
            })
          : dto.purpose === MediaPurpose.CATEGORY_IMAGE
            ? await this.dataSource.getRepository(MenuCategory).findOne({
                where: { id: dto.targetId, restaurantId: dto.restaurantId },
              })
            : await this.dataSource.getRepository(Ingredient).findOne({
                where: { id: dto.targetId, restaurantId: dto.restaurantId },
              });
      if (!entity) throw new NotFoundException('Image target not found');
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
