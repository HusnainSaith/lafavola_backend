import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CheckoutDto } from '../../src/modules/checkout/dto/checkout.dto';
import { MenuItem } from '../../src/modules/menu/entities/menu-item.entity';
import { BusinessHours } from '../../src/modules/restaurants/entities/business-hours.entity';
import { RestaurantsService } from '../../src/modules/restaurants/restaurants.service';

describe('customer ordering contract', () => {
  const cartId = '10000000-0000-4000-8000-000000000001';
  const addressId = '20000000-0000-4000-8000-000000000001';

  afterEach(() => jest.useRealTimers());

  it('accepts pickup without an address', async () => {
    const dto = plainToInstance(CheckoutDto, {
      cartId,
      orderType: 'pickup',
      paymentMethod: 'cash',
      idempotencyKey: 'customer-pickup-contract',
    });

    expect(await validate(dto)).toHaveLength(0);
  });

  it('requires an idempotency key for every checkout request', async () => {
    const dto = plainToInstance(CheckoutDto, {
      cartId,
      orderType: 'pickup',
      paymentMethod: 'cash',
    });

    expect((await validate(dto)).map((error) => error.property)).toContain(
      'idempotencyKey',
    );
  });
  it('requires an owned address identifier for delivery input', async () => {
    const missing = plainToInstance(CheckoutDto, {
      cartId,
      orderType: 'delivery',
      paymentMethod: 'cash',
      idempotencyKey: 'customer-delivery-missing-address',
    });
    const valid = plainToInstance(CheckoutDto, {
      cartId,
      orderType: 'delivery',
      deliveryAddressId: addressId,
      paymentMethod: 'cash',
      idempotencyKey: 'customer-delivery-contract',
    });

    expect((await validate(missing)).map((error) => error.property)).toContain(
      'deliveryAddressId',
    );
    expect(await validate(valid)).toHaveLength(0);
  });

  it('rejects invalid fulfilment modes and malformed scheduled times', async () => {
    const dto = plainToInstance(CheckoutDto, {
      cartId,
      orderType: 'dine_in',
      paymentMethod: 'cash',
      scheduledFor: 'tomorrow evening',
      idempotencyKey: 'customer-invalid-fulfilment',
    });

    const properties = (await validate(dto)).map((error) => error.property);
    expect(properties).toEqual(
      expect.arrayContaining(['orderType', 'scheduledFor']),
    );
  });

  it('publishes restaurant-local delivery slots that leave kitchen time and exclude closing time', async () => {
    jest.useFakeTimers().setSystemTime(new Date('2026-08-12T16:00:00.000Z'));
    const restaurant = {
      id: '30000000-0000-4000-8000-000000000001',
      name: 'La Favola',
      timezone: 'Europe/Rome',
      defaultDeliveryMinutes: 45,
      isActive: true,
    };
    const hours = [
      {
        restaurantId: restaurant.id,
        dayOfWeek: 3,
        opensAt: '18:00:00',
        closesAt: '20:00:00',
        isClosed: false,
      },
    ];
    const hoursRepository = { find: jest.fn().mockResolvedValue(hours) };
    const menuRepository = {
      findOne: jest.fn().mockResolvedValue({ preparationMinutes: 15 }),
    };
    const service = new RestaurantsService(
      {
        findOne: jest.fn().mockResolvedValue(restaurant),
      } as never,
      {
        getRepository: jest.fn((entity) =>
          entity === BusinessHours
            ? hoursRepository
            : entity === MenuItem
              ? menuRepository
              : undefined,
        ),
      } as never,
    );

    const result = await service.getPublicAvailability(
      'delivery',
      '2026-08-12',
      '40000000-0000-4000-8000-000000000001',
    );

    expect(result.timezone).toBe('Europe/Rome');
    expect(result.leadMinutes).toBe(45);
    expect(result.slots.map((slot) => slot.localTime)).toEqual([
      '18:45',
      '19:00',
      '19:15',
      '19:30',
      '19:45',
    ]);
    expect(menuRepository.findOne).toHaveBeenCalledWith({
      where: {
        id: '40000000-0000-4000-8000-000000000001',
        restaurantId: restaurant.id,
        isActive: true,
      },
    });
  });

  it('treats the configured closing instant as unavailable', async () => {
    const hoursRepository = {
      find: jest.fn().mockResolvedValue([
        {
          restaurantId: 'restaurant',
          dayOfWeek: 3,
          opensAt: '18:00:00',
          closesAt: '20:00:00',
          isClosed: false,
        },
      ]),
    };
    const service = new RestaurantsService(
      {} as never,
      {
        getRepository: jest.fn(() => hoursRepository),
      } as never,
    );

    await expect(
      service.assertOpenAt(
        'restaurant',
        'Europe/Rome',
        new Date('2026-08-12T18:00:00.000Z'),
      ),
    ).rejects.toThrow('closed at the requested fulfilment time');
  });
});
