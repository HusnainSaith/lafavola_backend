import { Module } from '@nestjs/common';
import { RestaurantRepository } from './repositories/restaurant.repository';
import { RestaurantsController } from './restaurants.controller';
import { RestaurantsService } from './restaurants.service';
import { PublicRestaurantsController } from './public-restaurants.controller';

@Module({
  controllers: [RestaurantsController, PublicRestaurantsController],
  providers: [RestaurantsService, RestaurantRepository],
  exports: [RestaurantsService, RestaurantRepository],
})
export class RestaurantsModule {}
