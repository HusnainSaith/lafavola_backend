import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Restaurant } from '../entities/restaurant.entity';

@Injectable()
export class RestaurantRepository extends BaseRepository<Restaurant> {
  constructor(dataSource: DataSource) {
    super(dataSource, Restaurant);
  }
}
