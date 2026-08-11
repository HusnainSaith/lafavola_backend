import { BadRequestException, Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { requireEntity } from '../../common/utils/service-errors.util';
import { UpsertBusinessHoursDto } from './dto/upsert-business-hours.dto';
import { UpdateRestaurantDto } from './dto/update-restaurant.dto';
import { BusinessHours } from './entities/business-hours.entity';
import { Restaurant } from './entities/restaurant.entity';
import { RestaurantRepository } from './repositories/restaurant.repository';
import { StaffMember } from '../staff/entities/staff-member.entity';

@Injectable()
export class RestaurantsService {
  constructor(
    private readonly restaurants: RestaurantRepository,
    private readonly dataSource: DataSource,
  ) {}

  async getSingleton(actorUserId: string): Promise<Restaurant> {
    const staff = requireEntity(
      await this.dataSource.getRepository(StaffMember).findOne({
        where: { userId: actorUserId, isActive: true },
      }),
      'Staff member not found',
    );
    return requireEntity(
      await this.restaurants.findOne({ where: { id: staff.restaurantId } }),
      'La Favola Restaurant is not configured',
    );
  }

  async updateSingleton(
    dto: UpdateRestaurantDto,
    actorUserId: string,
  ): Promise<Restaurant> {
    const entity = await this.getSingleton(actorUserId);
    Object.assign(entity, dto);
    return this.restaurants.save(entity);
  }

  async listBusinessHours(actorUserId: string): Promise<BusinessHours[]> {
    const restaurant = await this.getSingleton(actorUserId);
    return this.dataSource.getRepository(BusinessHours).find({
      where: { restaurantId: restaurant.id },
      order: { dayOfWeek: 'ASC' },
    });
  }

  async upsertBusinessHours(
    dto: UpsertBusinessHoursDto,
    actorUserId: string,
  ): Promise<BusinessHours> {
    const isClosed = dto.isClosed ?? false;
    if (isClosed && (dto.opensAt !== undefined || dto.closesAt !== undefined)) {
      throw new BadRequestException(
        'Closed business hours must not include opening or closing times',
      );
    }
    if (!isClosed && (!dto.opensAt || !dto.closesAt)) {
      throw new BadRequestException(
        'Open business hours require both opening and closing times',
      );
    }
    if (!isClosed && dto.closesAt! <= dto.opensAt!) {
      throw new BadRequestException('Closing time must be after opening time');
    }

    const restaurant = await this.getSingleton(actorUserId);
    const hours = this.dataSource.getRepository(BusinessHours);
    await hours.upsert(
      {
        restaurantId: restaurant.id,
        dayOfWeek: dto.dayOfWeek,
        opensAt: isClosed ? null : dto.opensAt,
        closesAt: isClosed ? null : dto.closesAt,
        isClosed,
      },
      ['restaurantId', 'dayOfWeek'],
    );
    return requireEntity(
      await hours.findOne({
        where: { restaurantId: restaurant.id, dayOfWeek: dto.dayOfWeek },
      }),
      'Business hours could not be saved',
    );
  }
}
