import { NotFoundException } from '@nestjs/common';
import { AddressesService } from '../../src/modules/addresses/addresses.service';
import { FavoritesService } from '../../src/modules/favorites/favorites.service';
import { OrdersService } from '../../src/modules/orders/orders.service';
import { SupportService } from '../../src/modules/support/support.service';
import { DeliveriesService } from '../../src/modules/deliveries/deliveries.service';

describe('customer ownership isolation', () => {
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
    const service = new FavoritesService(favorites as never);
    await expect(service.remove('user-a', 'favorite-b')).rejects.toBeDefined();
    expect(favorites.findOne).toHaveBeenCalledWith({
      where: { id: 'favorite-b', customerId: 'user-a' },
    });
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
