import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Favorite } from '../entities/favorite.entity';

@Injectable()
export class FavoriteRepository extends BaseRepository<Favorite> {
  constructor(dataSource: DataSource) {
    super(dataSource, Favorite);
  }
}
