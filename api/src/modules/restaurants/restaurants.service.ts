import { BadRequestException, Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { requireEntity } from '../../common/utils/service-errors.util';
import { UpsertBusinessHoursDto } from './dto/upsert-business-hours.dto';
import { UpdateRestaurantDto } from './dto/update-restaurant.dto';
import { BusinessHours } from './entities/business-hours.entity';
import { Restaurant } from './entities/restaurant.entity';
import { RestaurantRepository } from './repositories/restaurant.repository';
import { StaffMember } from '../staff/entities/staff-member.entity';
import { MenuItem } from '../menu/entities/menu-item.entity';

@Injectable()
export class RestaurantsService {
  constructor(
    private readonly restaurants: RestaurantRepository,
    private readonly dataSource: DataSource,
  ) {}

  async getPublicSingleton() {
    const restaurant = requireEntity(
      await this.restaurants.findOne({ where: { isActive: true } }),
      'La Favola Restaurant is not configured',
    );
    const hours = await this.dataSource.getRepository(BusinessHours).find({
      where: { restaurantId: restaurant.id },
      order: { dayOfWeek: 'ASC' },
    });
    return {
      id: restaurant.id,
      name: restaurant.name,
      phone: restaurant.phone ?? null,
      email: restaurant.email ?? null,
      address: {
        line1: restaurant.addressLine1 ?? null,
        line2: restaurant.addressLine2 ?? null,
        city: restaurant.city ?? null,
        province: restaurant.province ?? null,
        postalCode: restaurant.postalCode ?? null,
        countryCode: restaurant.countryCode,
      },
      timezone: restaurant.timezone,
      currency: restaurant.currency,
      fulfilment: {
        deliveryMinutes: restaurant.defaultDeliveryMinutes,
        deliveryFeeMinor: restaurant.deliveryFeeMinor,
        minimumOrderMinor: restaurant.minimumOrderMinor,
        deliveryEnabled: true,
        pickupEnabled: true,
      },
      hours: hours.map((entry) => ({
        dayOfWeek: entry.dayOfWeek,
        opensAt: entry.opensAt ?? null,
        closesAt: entry.closesAt ?? null,
        isClosed: entry.isClosed,
      })),
    };
  }

  async getPublicAvailability(
    orderType: 'delivery' | 'pickup',
    requestedDate?: string,
    menuItemId?: string,
  ) {
    const restaurant = requireEntity(
      await this.restaurants.findOne({ where: { isActive: true } }),
      'La Favola Restaurant is not configured',
    );
    const now = new Date();
    const today = localDate(now, restaurant.timezone);
    const date = requestedDate ?? today;
    const maximumDate = addCalendarDays(today, 14);
    if (date < today || date > maximumDate) {
      throw new BadRequestException(
        'Availability date must be within the next 14 days',
      );
    }
    const hours = await this.dataSource.getRepository(BusinessHours).find({
      where: { restaurantId: restaurant.id },
      order: { dayOfWeek: 'ASC' },
    });
    const menuItem = menuItemId
      ? await this.dataSource.getRepository(MenuItem).findOne({
          where: {
            id: menuItemId,
            restaurantId: restaurant.id,
            isActive: true,
          },
        })
      : null;
    const preparationMinutes = Number(menuItem?.preparationMinutes ?? 15);
    const leadMinutes =
      orderType === 'delivery'
        ? Math.max(
            preparationMinutes,
            Number(restaurant.defaultDeliveryMinutes),
          )
        : preparationMinutes;
    const transitMinutes =
      orderType === 'delivery'
        ? Math.max(
            5,
            Number(restaurant.defaultDeliveryMinutes) - preparationMinutes,
          )
        : 0;
    const earliest = new Date(now.getTime() + leadMinutes * 60_000);
    const day = dayOfWeek(date);
    const configured = hours.find((entry) => entry.dayOfWeek === day);
    const slots: Array<{ scheduledFor: string; localTime: string }> = [];
    if (
      configured &&
      !configured.isClosed &&
      configured.opensAt &&
      configured.closesAt
    ) {
      const openMinutes = timeToMinutes(configured.opensAt);
      let closeMinutes = timeToMinutes(configured.closesAt);
      if (closeMinutes <= openMinutes) closeMinutes += 24 * 60;
      for (
        let minute = roundUp(openMinutes + transitMinutes, 15);
        minute < closeMinutes;
        minute += 15
      ) {
        const slotDate = minute >= 24 * 60 ? addCalendarDays(date, 1) : date;
        const localMinute = minute % (24 * 60);
        const localTime = minutesToTime(localMinute);
        const scheduledFor = zonedLocalToUtc(
          slotDate,
          localTime,
          restaurant.timezone,
        );
        if (scheduledFor >= earliest) {
          slots.push({ scheduledFor: scheduledFor.toISOString(), localTime });
        }
      }
    }
    const asapAvailable = await this.isOpenAt(
      restaurant.id,
      restaurant.timezone,
      now,
      hours,
    );
    return {
      serverNow: now,
      timezone: restaurant.timezone,
      date,
      orderType,
      leadMinutes,
      preparationMinutes,
      asapAvailable,
      estimatedReadyAt: asapAvailable
        ? new Date(now.getTime() + preparationMinutes * 60_000)
        : null,
      estimatedDeliveryAt:
        asapAvailable && orderType === 'delivery'
          ? new Date(now.getTime() + leadMinutes * 60_000)
          : null,
      slots,
    };
  }

  async assertOpenAt(restaurantId: string, timezone: string, serviceAt: Date) {
    if (!(await this.isOpenAt(restaurantId, timezone, serviceAt))) {
      throw new BadRequestException(
        'La Favola is closed at the requested fulfilment time',
      );
    }
  }

  private async isOpenAt(
    restaurantId: string,
    timezone: string,
    instant: Date,
    existingHours?: BusinessHours[],
  ): Promise<boolean> {
    const hours =
      existingHours ??
      (await this.dataSource.getRepository(BusinessHours).find({
        where: { restaurantId },
      }));
    // An empty schedule is treated as not-yet-configured so existing
    // development installations continue to accept orders explicitly.
    if (!hours.length) return true;
    const date = localDate(instant, timezone);
    const time = localTime(instant, timezone);
    const minute = timeToMinutes(time);
    const currentDay = dayOfWeek(date);
    const current = hours.find((entry) => entry.dayOfWeek === currentDay);
    if (matchesHours(current, minute, false)) return true;
    const previousDay = (currentDay + 6) % 7;
    const previous = hours.find((entry) => entry.dayOfWeek === previousDay);
    return matchesHours(previous, minute, true);
  }

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

function localParts(instant: Date, timezone: string) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: timezone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(instant);
  return Object.fromEntries(parts.map((part) => [part.type, part.value]));
}

function localDate(instant: Date, timezone: string) {
  const parts = localParts(instant, timezone);
  return `${parts.year}-${parts.month}-${parts.day}`;
}

function localTime(instant: Date, timezone: string) {
  const parts = localParts(instant, timezone);
  return `${parts.hour}:${parts.minute}`;
}

function dayOfWeek(date: string) {
  return new Date(`${date}T12:00:00Z`).getUTCDay();
}

function addCalendarDays(date: string, days: number) {
  const value = new Date(`${date}T12:00:00Z`);
  value.setUTCDate(value.getUTCDate() + days);
  return value.toISOString().slice(0, 10);
}

function timeToMinutes(time: string) {
  const [hour, minute] = time.slice(0, 5).split(':').map(Number);
  return hour * 60 + minute;
}

function minutesToTime(value: number) {
  return `${String(Math.floor(value / 60)).padStart(2, '0')}:${String(
    value % 60,
  ).padStart(2, '0')}`;
}

function roundUp(value: number, interval: number) {
  return Math.ceil(value / interval) * interval;
}

function matchesHours(
  hours: BusinessHours | undefined,
  minute: number,
  previousDay: boolean,
) {
  if (!hours || hours.isClosed || !hours.opensAt || !hours.closesAt)
    return false;
  const opens = timeToMinutes(hours.opensAt);
  const closes = timeToMinutes(hours.closesAt);
  if (closes > opens) return !previousDay && minute >= opens && minute < closes;
  return previousDay ? minute < closes : minute >= opens;
}

function zonedLocalToUtc(date: string, time: string, timezone: string) {
  const guess = new Date(`${date}T${time}:00Z`);
  const parts = localParts(guess, timezone);
  const represented = Date.UTC(
    Number(parts.year),
    Number(parts.month) - 1,
    Number(parts.day),
    Number(parts.hour),
    Number(parts.minute),
  );
  return new Date(guess.getTime() - (represented - guess.getTime()));
}
