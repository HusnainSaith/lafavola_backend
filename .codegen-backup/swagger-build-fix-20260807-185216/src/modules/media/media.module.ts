import { Module } from '@nestjs/common';
import { MediaController } from './media.controller';
import { MediaService } from './media.service';
import { MediaAssetRepository } from './repositories/media-asset.repository';

@Module({
  controllers: [MediaController],
  providers: [MediaService, MediaAssetRepository],
  exports: [MediaService],
})
export class MediaModule {}
