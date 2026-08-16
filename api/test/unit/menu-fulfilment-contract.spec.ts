import { MenuService } from '../../src/modules/menu/menu.service';

describe('menu product fulfilment contract', () => {
  it('publishes the admin delivery fee and free pickup on product detail', async () => {
    const item = {
      id: 'item-id',
      isActive: true,
      restaurant: {
        isActive: true,
        currency: 'EUR',
        deliveryFeeMinor: 350,
        minimumOrderMinor: 1000,
        defaultDeliveryMinutes: 30,
      },
    };
    const items = { findOne: jest.fn().mockResolvedValue(item) };
    const service = new MenuService({} as never, items as never);

    const result = await service.detail('item-id');

    expect(result.fulfilment).toEqual({
      currency: 'EUR',
      minimumOrderMinor: 1000,
      delivery: { enabled: true, feeMinor: 350, estimatedMinutes: 30 },
      pickup: { enabled: true, feeMinor: 0 },
    });
  });
});
