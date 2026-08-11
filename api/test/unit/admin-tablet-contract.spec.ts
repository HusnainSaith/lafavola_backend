import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { CategoriesService } from '../../src/modules/categories/categories.service';
import { MediaService } from '../../src/modules/media/media.service';
import { OrdersService } from '../../src/modules/orders/orders.service';
import { OptionGroupsService } from '../../src/modules/option-groups/option-groups.service';
import { RestaurantsService } from '../../src/modules/restaurants/restaurants.service';
import { RefundsService } from '../../src/modules/refunds/refunds.service';
import { ReportsService } from '../../src/modules/reports/reports.service';
import { StaffService } from '../../src/modules/staff/staff.service';
import { PizzaBuilderService } from '../../src/modules/pizza-builder/pizza-builder.service';

describe('admin tablet contract services', () => {
  it('returns an admin order detail only from the actor staff restaurant', async () => {
    const items = [{ id: 'line-1', orderId: 'order-1' }];
    const optionsQuery = {
      where: jest.fn().mockReturnThis(),
      getMany: jest.fn().mockResolvedValue([{ orderItemId: 'line-1' }]),
    };
    const dataSource = {
      getRepository: jest
        .fn()
        .mockReturnValueOnce({
          findOne: jest
            .fn()
            .mockResolvedValue({ restaurantId: 'restaurant-1' }),
        })
        .mockReturnValueOnce({ find: jest.fn().mockResolvedValue(items) })
        .mockReturnValueOnce({
          createQueryBuilder: jest.fn(() => optionsQuery),
        })
        .mockReturnValueOnce({
          find: jest.fn().mockResolvedValue([{ id: 'event-1' }]),
        }),
    };
    const orders = { findOne: jest.fn().mockResolvedValue({ id: 'order-1' }) };
    const service = new OrdersService(
      dataSource as never,
      orders as never,
      {} as never,
      {} as never,
      {} as never,
    );

    await expect(service.adminDetail('order-1', 'admin-1')).resolves.toEqual({
      order: { id: 'order-1' },
      items,
      options: [{ orderItemId: 'line-1' }],
      statusHistory: [{ id: 'event-1' }],
    });
    expect(orders.findOne).toHaveBeenCalledWith({
      where: { id: 'order-1', restaurantId: 'restaurant-1' },
    });
  });

  it('continues to scope customer detail by the authenticated customer', async () => {
    const orders = { findOne: jest.fn().mockResolvedValue(null) };
    const service = new OrdersService(
      {} as never,
      orders as never,
      {} as never,
      {} as never,
      {} as never,
    );

    await expect(
      service.customerDetail('customer-1', 'order-2'),
    ).rejects.toBeDefined();
    expect(orders.findOne).toHaveBeenCalledWith({
      where: { id: 'order-2', customerId: 'customer-1' },
    });
  });

  it('never accepts a client-supplied restaurant for the admin order queue', async () => {
    const staff = {
      findOne: jest.fn().mockResolvedValue({ restaurantId: 'restaurant-1' }),
    };
    const orders = { findMany: jest.fn().mockResolvedValue([]) };
    const service = new OrdersService(
      { getRepository: jest.fn(() => staff) } as never,
      orders as never,
      {} as never,
      {} as never,
      {} as never,
    );

    await expect(service.listAdmin('admin-1', 'ready')).resolves.toEqual([]);
    expect(orders.findMany).toHaveBeenCalledWith({
      where: { restaurantId: 'restaurant-1', status: 'ready' },
      order: { createdAt: 'DESC' },
    });
  });

  it('rejects an admin order status mutation outside the actor restaurant', async () => {
    const staff = {
      findOne: jest.fn().mockResolvedValue({ restaurantId: 'restaurant-1' }),
    };
    const orders = { findOne: jest.fn().mockResolvedValue(null) };
    const service = new OrdersService(
      { getRepository: jest.fn(() => staff) } as never,
      orders as never,
      {} as never,
      {} as never,
      {} as never,
    );

    await expect(
      service.updateAdminStatus(
        'foreign-order',
        { status: 'accepted' } as never,
        'admin-1',
      ),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(orders.findOne).toHaveBeenCalledWith({
      where: { id: 'foreign-order', restaurantId: 'restaurant-1' },
    });
  });

  it('validates open hours and atomically upserts them for the actor restaurant', async () => {
    const staff = {
      findOne: jest.fn().mockResolvedValue({ restaurantId: 'restaurant-1' }),
    };
    const hours = {
      upsert: jest.fn().mockResolvedValue(undefined),
      findOne: jest.fn().mockResolvedValue({
        id: 'hours-1',
        restaurantId: 'restaurant-1',
        dayOfWeek: 1,
        opensAt: '10:00',
        closesAt: '22:00',
        isClosed: false,
      }),
    };
    const restaurants = {
      findOne: jest.fn().mockResolvedValue({ id: 'restaurant-1' }),
    };
    const service = new RestaurantsService(
      restaurants as never,
      {
        getRepository: jest
          .fn()
          .mockReturnValueOnce(staff)
          .mockReturnValueOnce(hours),
      } as never,
    );

    await expect(
      service.upsertBusinessHours(
        { dayOfWeek: 1, opensAt: '18:00', closesAt: '17:59' },
        'admin-1',
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      service.upsertBusinessHours(
        { dayOfWeek: 1, opensAt: '10:00', closesAt: '22:00' },
        'admin-1',
      ),
    ).resolves.toMatchObject({ restaurantId: 'restaurant-1' });
    expect(restaurants.findOne).toHaveBeenCalledWith({
      where: { id: 'restaurant-1' },
    });
    expect(hours.upsert).toHaveBeenCalledWith(
      {
        restaurantId: 'restaurant-1',
        dayOfWeek: 1,
        opensAt: '10:00',
        closesAt: '22:00',
        isClosed: false,
      },
      ['restaurantId', 'dayOfWeek'],
    );
  });

  it('prevents a staff profile update across restaurant boundaries', async () => {
    const staff = {
      findOne: jest
        .fn()
        .mockResolvedValueOnce({ restaurantId: 'restaurant-1' })
        .mockResolvedValueOnce(null),
      save: jest.fn(),
    };
    const service = new StaffService(staff as never);

    await expect(
      service.update('staff-2', { jobTitle: 'Head cook' }, 'admin-1'),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(staff.findOne).toHaveBeenLastCalledWith({
      where: { id: 'staff-2', restaurantId: 'restaurant-1' },
    });
  });

  it('lists refunds for an admin only within the actor staff restaurant', async () => {
    const staff = {
      findOne: jest.fn().mockResolvedValue({ restaurantId: 'restaurant-1' }),
    };
    const orders = {
      findOne: jest.fn().mockResolvedValue({ id: 'order-1' }),
    };
    const refunds = {
      find: jest
        .fn()
        .mockResolvedValue([{ id: 'refund-1', orderId: 'order-1' }]),
    };
    const repositoryFor = (entity: { name: string }) => {
      if (entity.name === 'StaffMember') return staff;
      if (entity.name === 'Order') return orders;
      return refunds;
    };
    const dataSource = {
      manager: { getRepository: jest.fn(repositoryFor) },
      getRepository: jest.fn(repositoryFor),
    };
    const service = new RefundsService(dataSource as never, {} as never);

    await expect(
      service.listForOrder('admin-1', 'order-1', true),
    ).resolves.toEqual([{ id: 'refund-1', orderId: 'order-1' }]);
    expect(orders.findOne).toHaveBeenCalledWith({
      where: { id: 'order-1', restaurantId: 'restaurant-1' },
    });
    expect(refunds.find).toHaveBeenCalledWith({
      where: { orderId: 'order-1' },
      order: { createdAt: 'DESC' },
    });
  });

  it('scopes choice changes and ingredient references to the actor restaurant', async () => {
    const choice = {
      id: 'choice-1',
      optionGroupId: 'group-1',
      name: 'Mushrooms',
      isActive: true,
    };
    const staffRepository = {
      findOne: jest.fn().mockResolvedValue({ restaurantId: 'restaurant-1' }),
    };
    const choiceRepository = {
      findOne: jest.fn().mockResolvedValue(choice),
      save: jest.fn(async (value) => value),
    };
    const ingredients = { findOne: jest.fn().mockResolvedValue(null) };
    const dataSource = {
      getRepository: jest.fn((entity: { name: string }) => {
        if (entity.name === 'StaffMember') return staffRepository;
        if (entity.name === 'Ingredient') return ingredients;
        return choiceRepository;
      }),
    };
    const groups = {
      findOne: jest.fn().mockResolvedValue({
        id: 'group-1',
        restaurantId: 'restaurant-1',
      }),
    };
    const service = new OptionGroupsService(
      dataSource as never,
      groups as never,
    );

    await expect(
      service.updateChoice(
        'group-1',
        'choice-1',
        { ingredientId: 'foreign-ingredient' },
        'admin-1',
      ),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(ingredients.findOne).toHaveBeenCalledWith({
      where: {
        id: 'foreign-ingredient',
        restaurantId: 'restaurant-1',
        isActive: true,
      },
    });

    ingredients.findOne.mockResolvedValue({ id: 'ingredient-1' });
    await expect(
      service.deactivateChoice('group-1', 'choice-1', 'admin-1'),
    ).resolves.toMatchObject({ isActive: false });
    expect((choiceRepository as { delete?: jest.Mock }).delete).toBeUndefined();

    groups.findOne.mockResolvedValue(null);
    await expect(
      service.deactivateChoice('other-group', 'choice-1', 'admin-1'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('prevents creating or deactivating an option group outside the actor restaurant', async () => {
    const staffRepository = {
      findOne: jest.fn().mockResolvedValue({ restaurantId: 'restaurant-1' }),
    };
    const groups = {
      create: jest.fn((value) => value),
      findOne: jest.fn().mockResolvedValue(null),
      save: jest.fn(async (value) => value),
    };
    const service = new OptionGroupsService(
      {
        getRepository: jest.fn(() => staffRepository),
      } as never,
      groups as never,
    );

    await expect(
      service.create(
        {
          restaurantId: 'restaurant-2',
          name: 'Foreign extras',
          code: 'foreign-extras',
          optionType: 'multiple' as never,
        },
        'admin-1',
      ),
    ).rejects.toBeInstanceOf(NotFoundException);

    await expect(
      service.deactivate('group-2', 'admin-1'),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(groups.findOne).toHaveBeenCalledWith({
      where: { id: 'group-2', restaurantId: 'restaurant-1' },
    });
  });

  it('derives financial report scope from the authenticated staff member', async () => {
    const query = jest.fn().mockResolvedValue([
      {
        totalOrders: 0,
        successfulOrders: 0,
        netRevenueMinor: 0,
      },
    ]);
    const dataSource = {
      getRepository: jest.fn().mockReturnValue({
        findOne: jest.fn().mockResolvedValue({
          restaurantId: 'restaurant-owned',
        }),
      }),
      query,
    };
    const service = new ReportsService(dataSource as never);

    await service.salesForAdmin('admin-1', {
      restaurantId: 'restaurant-foreign',
      from: '2026-08-01',
      to: '2026-08-11',
    });

    expect(query).toHaveBeenCalledWith(expect.any(String), [
      'restaurant-owned',
      '2026-08-01',
      '2026-08-11',
    ]);
  });

  it('rejects catalogue creation for a client-supplied restaurant', async () => {
    const repository = { save: jest.fn(), create: jest.fn() };
    const service = new CategoriesService(
      repository as never,
      {
        getRepository: jest.fn().mockReturnValue({
          findOne: jest.fn().mockResolvedValue({
            restaurantId: 'restaurant-owned',
          }),
        }),
      } as never,
    );

    await expect(
      service.create(
        {
          restaurantId: 'restaurant-foreign',
          name: 'Foreign',
          slug: 'foreign',
        } as never,
        'admin-1',
      ),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(repository.save).not.toHaveBeenCalled();
  });

  it('prevents an administrator from deactivating their own staff access', async () => {
    const staff = {
      findOne: jest.fn().mockResolvedValue({
        id: 'staff-1',
        userId: 'admin-1',
        restaurantId: 'restaurant-1',
        isActive: true,
      }),
      save: jest.fn(),
    };
    const service = new StaffService(staff as never);

    await expect(
      service.deactivate('staff-1', 'admin-1'),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(staff.save).not.toHaveBeenCalled();
  });

  it('requires active La Favola staff membership for menu media uploads', async () => {
    const storage = { put: jest.fn() };
    const service = new MediaService(
      {
        getRepository: jest.fn().mockReturnValue({
          findOne: jest.fn().mockResolvedValue({ id: 'menu-1' }),
        }),
        query: jest.fn().mockResolvedValue([]),
      } as never,
      {} as never,
      storage as never,
    );

    await expect(
      service.upload(
        'admin-1',
        {
          mimetype: 'image/png',
          size: 10,
          originalname: 'pizza.png',
          buffer: Buffer.from('image'),
        } as never,
        {
          purpose: 'menu_image',
          restaurantId: 'restaurant-foreign',
          targetId: 'menu-1',
        } as never,
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(storage.put).not.toHaveBeenCalled();
  });

  it('rejects pizza-builder rules that reference a foreign menu item', async () => {
    const service = new PizzaBuilderService(
      { save: jest.fn(), create: jest.fn() } as never,
      {} as never,
      {
        getRepository: jest.fn((entity: { name: string }) =>
          entity.name === 'StaffMember'
            ? {
                findOne: jest.fn().mockResolvedValue({
                  restaurantId: 'restaurant-owned',
                }),
              }
            : { findOne: jest.fn().mockResolvedValue(null) },
        ),
      } as never,
    );

    await expect(
      service.createAdmin('admin-1', {
        menuItemId: 'foreign-menu',
        name: 'Foreign builder',
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});
