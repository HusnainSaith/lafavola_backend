import { NotFoundException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { DeliveriesService } from '../../src/modules/deliveries/deliveries.service';
import { CreateDriverDto } from '../../src/modules/deliveries/dto/create-driver.dto';

describe('delivery administration contract', () => {
  it('validates and normalizes driver creation input', async () => {
    const valid = plainToInstance(CreateDriverDto, {
      fullName: '  Mario Rossi  ',
      email: '  MARIO@EXAMPLE.COM ',
      phone: '+393331234567',
      temporaryPassword: 'Temporary-2026',
      employeeCode: 'LF-DRV-1',
    });
    expect(await validate(valid)).toHaveLength(0);
    expect(valid.fullName).toBe('Mario Rossi');
    expect(valid.email).toBe('mario@example.com');

    const invalid = plainToInstance(CreateDriverDto, {
      fullName: ' ',
      email: 'not-an-email',
      temporaryPassword: 'short',
    });
    const errors = await validate(invalid);
    expect(errors.map((error) => error.property)).toEqual(
      expect.arrayContaining(['fullName', 'email', 'temporaryPassword']),
    );
  });

  it('rejects assigning a user who is not an active driver in the restaurant', async () => {
    const driverQuery = {
      innerJoin: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      getOne: jest.fn().mockResolvedValue(null),
    };
    const staffRepository = {
      findOne: jest.fn().mockResolvedValue({
        userId: 'admin-1',
        restaurantId: 'restaurant-1',
        isActive: true,
      }),
      createQueryBuilder: jest.fn(() => driverQuery),
    };
    const orderRepository = {
      findOne: jest.fn().mockResolvedValue({
        id: 'order-1',
        restaurantId: 'restaurant-1',
        orderType: 'delivery',
        status: 'ready',
      }),
    };
    const manager = {
      getRepository: jest.fn((entity: { name: string }) => {
        if (entity.name === 'StaffMember') return staffRepository;
        if (entity.name === 'Order') return orderRepository;
        return {};
      }),
    };
    const dataSource = {
      transaction: jest.fn(async (callback) => callback(manager)),
    };
    const service = new DeliveriesService(
      dataSource as never,
      {} as never,
      { enqueue: jest.fn() } as never,
    );

    await expect(
      service.assign('order-1', 'admin-1', {
        driverUserId: '00000000-0000-4000-8000-000000000002',
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(driverQuery.andWhere).toHaveBeenCalledWith(
      'driverStaff.restaurant_id = :restaurantId',
      { restaurantId: 'restaurant-1' },
    );
    expect(driverQuery.andWhere).toHaveBeenCalledWith(
      'LOWER(driverStaff.job_title) = :jobTitle',
      { jobTitle: 'driver' },
    );
    expect(driverQuery.andWhere).toHaveBeenCalledWith(
      'driverRole.name = :role',
      { role: 'employee' },
    );
  });

  it('returns a named driver directory without exposing account internals', async () => {
    const driverQuery = {
      innerJoinAndSelect: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      addOrderBy: jest.fn().mockReturnThis(),
      getMany: jest.fn().mockResolvedValue([
        {
          id: 'staff-1',
          userId: 'driver-1',
          employeeCode: 'LF-D1',
          jobTitle: 'Driver',
          isActive: true,
          user: {
            id: 'driver-1',
            fullName: 'Mario Rossi',
            email: 'mario@example.com',
            phone: '+393331234567',
            password: 'must-not-leak',
          },
        },
      ]),
    };
    const repository = {
      findOne: jest.fn().mockResolvedValue({
        userId: 'admin-1',
        restaurantId: 'restaurant-1',
        isActive: true,
      }),
      createQueryBuilder: jest.fn(() => driverQuery),
    };
    const service = new DeliveriesService(
      { getRepository: jest.fn(() => repository) } as never,
      {} as never,
      {} as never,
    );

    const drivers = await service.listDrivers('admin-1');
    expect(drivers).toEqual([
      {
        id: 'staff-1',
        userId: 'driver-1',
        fullName: 'Mario Rossi',
        email: 'mario@example.com',
        phone: '+393331234567',
        employeeCode: 'LF-D1',
        jobTitle: 'Driver',
        isActive: true,
      },
    ]);
    expect(JSON.stringify(drivers)).not.toContain('must-not-leak');
  });
});
