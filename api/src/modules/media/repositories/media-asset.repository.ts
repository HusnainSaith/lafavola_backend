import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { MediaAsset } from '../entities/media-asset.entity';

@Injectable()
export class MediaAssetRepository extends BaseRepository<MediaAsset> {
  constructor(dataSource: DataSource) {
    super(dataSource, MediaAsset);
  }
}
