import { NotFoundException } from '@nestjs/common';
import { AddressesService } from '../../src/modules/addresses/addresses.service';
import { FavoritesService } from '../../src/modules/favorites/favorites.service';
import { OrdersService } from '../../src/modules/orders/orders.service';
import { SupportService } from '../../src/modules/support/support.service';
import { DeliveriesService } from '../../src/modules/deliveries/deliveries.service';
import { RolesGuard } from '../../src/common/guards/roles.guard';
import { RoleEnum } from '../../src/modules/roles/role.enum';
import { MenuItem } from '../../src/modules/menu/entities/menu-item.entity';
import { MenuItemSize } from '../../src/modules/menu/entities/menu-item-size.entity';

describe('customer ownership isolation', () => {
  it('does not treat any recognized role as satisfying an admin requirement', () => {
    const reflector = {
      getAllAndOverride: jest.fn().mockReturnValue([RoleEnum.ADMIN]),
    };
    const guard = new RolesGuard(reflector as never);
    const context = {
      getHandler: jest.fn(),
      getClass: jest.fn(),
      switchToHttp: () => ({
        getRequest: () => ({ user: { role: { name: RoleEnum.CLIENT } } }),
      }),
    };
    expect(() => guard.canActivate(context as never)).toThrow(
      'Access denied. Required roles: admin. User role: client',
    );
  });

  it('scopes address lookup by both resource and customer IDs', async () => {
    const addresses = { findOne: jest.fn().mockResolvedValue(null) };
    const service = new AddressesService({} as never, addresses as never);
    await expect(service.remove('user-a', 'address-b')).rejects.toBeInstanceOf(
      NotFoundException,
    );
    expect(addresses.findOne).toHaveBeenCalledWith({
      where: { id: 'address-b', customerId: 'user-a', isActive: true },
    });
  });

  it('scopes favorites by the authenticated customer', async () => {
    const favorites = { findOne: jest.fn().mockResolvedValue(null) };
    const service = new FavoritesService(
      favorites as never,
      {} as never,
      {} as never,
    );
    await expect(service.remove('user-a', 'favorite-b')).rejects.toBeDefined();
    expect(favorites.findOne).toHaveBeenCalledWith({
      where: { id: 'favorite-b', customerId: 'user-a' },
    });
  });

  it('revalidates an owned favorite through authoritative cart pricing', async () => {
    const favorites = {
      findOne: jest.fn().mockResolvedValue({
        id: 'favorite-a',
        customerId: 'user-a',
        restaurantId: 'restaurant-a',
        menuItemId: 'menu-a',
        configurationSnapshot: { menuItemSizeId: 'size-a', options: [] },
      }),
    };
    const carts = { addItemsAtomic: jest.fn().mockResolvedValue({}) };
    const service = new FavoritesService(
      favorites as never,
      carts as never,
      {} as never,
    );
    await service.addToCart('user-a', 'favorite-a', 2);
    expect(favorites.findOne).toHaveBeenCalledWith({
      where: { id: 'favorite-a', customerId: 'user-a' },
    });
    expect(carts.addItemsAtomic).toHaveBeenCalledWith(
      'user-a',
      'restaurant-a',
      [
        expect.objectContaining({
          menuItemId: 'menu-a',
          menuItemSizeId: 'size-a',
          quantity: 2,
        }),
      ],
    );
  });

  it('resolves an active default size when saving a menu favorite', async () => {
    const favorites = {
      findOne: jest.fn().mockResolvedValue(null),
      create: jest.fn((value) => value),
      save: jest.fn(async (value) => ({ id: 'favorite-a', ...value })),
    };
    const menuItems = {
      findOne: jest.fn().mockResolvedValue({
        id: 'menu-a',
        restaurantId: 'restaurant-a',
        isActive: true,
        archivedAt: null,
      }),
    };
    const sizes = {
      findOne: jest.fn().mockResolvedValue({ id: 'size-a' }),
    };
    const dataSource = {
      getRepository: jest.fn((entity) => {
        if (entity === MenuItem) return menuItems;
        if (entity === MenuItemSize) return sizes;
        throw new Error('Unexpected entity: ' + String(entity));
      }),
    };
    const service = new FavoritesService(
      favorites as never,
      {} as never,
      dataSource as never,
    );

    await service.create('user-a', {
      restaurantId: 'restaurant-a',
      menuItemId: 'menu-a',
      label: 'Pizza preferita',
    });

    expect(sizes.findOne).toHaveBeenCalledWith({
      where: { menuItemId: 'menu-a', isActive: true },
      order: { displayOrder: 'ASC', basePriceMinor: 'ASC' },
    });
    expect(favorites.save).toHaveBeenCalledWith(
      expect.objectContaining({
        customerId: 'user-a',
        configurationSnapshot: { menuItemSizeId: 'size-a' },
      }),
    );
  });
  it('scopes order detail by the authenticated customer', async () => {
    const orders = { findOne: jest.fn().mockResolvedValue(null) };
    const service = new OrdersService(
      {} as never,
      orders as never,
      {} as never,
      {} as never,
      {} as never,
    );
    await expect(
      service.customerDetail('user-a', 'order-b'),
    ).rejects.toBeDefined();
    expect(orders.findOne).toHaveBeenCalledWith({
      where: { id: 'order-b', customerId: 'user-a' },
    });
  });

  it('scopes support ticket detail by the authenticated customer', async () => {
    const tickets = { findById: jest.fn().mockResolvedValue(null) };
    const service = new SupportService(
      {} as never,
      tickets as never,
      {} as never,
    );
    await expect(service.detail('user-a', 'ticket-b')).rejects.toBeInstanceOf(
      NotFoundException,
    );
    expect(tickets.findById).toHaveBeenCalledWith('ticket-b');
  });

  it('checks order ownership before exposing delivery tracking', async () => {
    const orderRepository = { findOne: jest.fn().mockResolvedValue(null) };
    const dataSource = {
      getRepository: jest.fn().mockReturnValue(orderRepository),
    };
    const tracking = { findByOrderId: jest.fn() };
    const service = new DeliveriesService(
      dataSource as never,
      tracking as never,
      { enqueue: jest.fn() } as never,
    );
    await expect(
      service.getTracking('user-a', 'order-b'),
    ).rejects.toBeDefined();
    expect(orderRepository.findOne).toHaveBeenCalledWith({
      where: { id: 'order-b', customerId: 'user-a' },
    });
    expect(tracking.findByOrderId).not.toHaveBeenCalled();
  });
});
