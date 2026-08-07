import { Injectable } from '@nestjs/common';
import { MediaAssetRepository } from './repositories/media-asset.repository';
import { CreateUploadUrlDto } from './dto/create-upload-url.dto';

@Injectable()
export class MediaService {
  constructor(private readonly assets: MediaAssetRepository) {}

  async registerPendingUpload(userId: string, dto: CreateUploadUrlDto) {
    const key = `restaurants/${dto.restaurantId ?? 'shared'}/${Date.now()}-${Math.random()
      .toString(36)
      .slice(2)}-${dto.fileName.replace(/[^a-zA-Z0-9._-]/g, '_')}`;

    const asset = await this.assets.save(
      this.assets.create({
        restaurantId: dto.restaurantId,
        uploadedByUserId: userId,
        storageProvider: 'aws_s3',
        bucket: process.env.AWS_S3_BUCKET ?? '',
        objectKey: key,
        mimeType: dto.mimeType,
        sizeBytes: String(dto.sizeBytes),
        altText: dto.altText,
        status: 'pending',
      }),
    );

    return {
      asset,
      objectKey: key,
      uploadStrategy: 'presigned-url',
      note: 'Use the AWS S3 integration service to generate the presigned PUT URL.',
    };
  }
}
