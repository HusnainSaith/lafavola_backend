import { Injectable } from '@nestjs/common';
import { requireEntity } from '../../common/utils/service-errors.util';
import { CreateRestaurantDto } from './dto/create-restaurant.dto';
import { UpdateRestaurantDto } from './dto/update-restaurant.dto';
import { Restaurant } from './entities/restaurant.entity';
import { RestaurantRepository } from './repositories/restaurant.repository';

@Injectable()
export class RestaurantsService {
  constructor(private readonly restaurants: RestaurantRepository) {}

  findAll(): Promise<Restaurant[]> {
    return this.restaurants.findMany({ order: { createdAt: 'DESC' } });
  }

  async findById(id: string): Promise<Restaurant> {
    return requireEntity(
      await this.restaurants.findById(id),
      'Restaurant not found',
    );
  }

  async create(dto: CreateRestaurantDto): Promise<Restaurant> {
    const existing = await this.restaurants.findOne({
      where: { slug: dto.slug },
    });
    if (existing) {
      throw new Error('Restaurant slug already exists');
    }
    return this.restaurants.save(
      this.restaurants.create({
        ...dto,
        currency: 'EUR',
        timezone: dto.timezone ?? 'Europe/Rome',
        defaultDeliveryMinutes: dto.defaultDeliveryMinutes ?? 30,
        deliveryFeeMinor: dto.deliveryFeeMinor ?? 0,
        minimumOrderMinor: dto.minimumOrderMinor ?? 0,
        taxRateBasisPoints: dto.taxRateBasisPoints ?? 0,
        isActive: dto.isActive ?? true,
      }),
    );
  }

  async update(id: string, dto: UpdateRestaurantDto): Promise<Restaurant> {
    const entity = await this.findById(id);
    Object.assign(entity, dto);
    return this.restaurants.save(entity);
  }

  async remove(id: string): Promise<void> {
    const entity = await this.findById(id);
    entity.isActive = false;
    await this.restaurants.save(entity);
  }
}
