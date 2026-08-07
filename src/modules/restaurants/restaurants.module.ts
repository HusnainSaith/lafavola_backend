import { Module } from '@nestjs/common';
import { RestaurantsController } from './restaurants.controller';
import { RestaurantsService } from './restaurants.service';
import { RestaurantRepository } from './repositories/restaurant.repository';

@Module({
  controllers: [RestaurantsController],
  providers: [RestaurantsService, RestaurantRepository],
  exports: [RestaurantsService, RestaurantRepository],
})
export class RestaurantsModule {}
