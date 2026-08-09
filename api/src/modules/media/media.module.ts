import { Module } from '@nestjs/common';
import { MediaController } from './media.controller';
import { MediaService } from './media.service';
import { MediaAssetRepository } from './repositories/media-asset.repository';
import { S3Module } from '../../integrations/aws/s3/s3.module';

@Module({
  imports: [S3Module],
  controllers: [MediaController],
  providers: [MediaService, MediaAssetRepository],
  exports: [MediaService],
})
export class MediaModule {}
