import { Injectable } from '@nestjs/common';
import { requireEntity } from '../../common/utils/service-errors.util';
import { UpdateRestaurantDto } from './dto/update-restaurant.dto';
import { Restaurant } from './entities/restaurant.entity';
import { RestaurantRepository } from './repositories/restaurant.repository';

@Injectable()
export class RestaurantsService {
  constructor(private readonly restaurants: RestaurantRepository) {}

  async updateSingleton(dto: UpdateRestaurantDto): Promise<Restaurant> {
    const entity = requireEntity(
      await this.restaurants.findOne({ order: { createdAt: 'ASC' } }),
      'La Favola Restaurant is not configured',
    );
    Object.assign(entity, dto);
    return this.restaurants.save(entity);
  }
}
