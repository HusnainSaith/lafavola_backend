import { CartsService } from '../../src/modules/carts/carts.service';
import { Restaurant } from '../../src/modules/restaurants/entities/restaurant.entity';

describe('cart restaurant contract', () => {
  it('uses the active restaurant when restaurantId is omitted', async () => {
    const carts = {
      findOne: jest.fn().mockResolvedValue({ id: 'cart-id' }),
      create: jest.fn(),
      save: jest.fn(),
    };
    const restaurantRepository = {
      findOne: jest.fn().mockResolvedValue({ id: 'restaurant-id' }),
    };
    const cartItemRepository = { find: jest.fn().mockResolvedValue([]) };
    const dataSource = {
      getRepository: jest.fn((entity) => {
        if (entity === Restaurant) return restaurantRepository;
        return cartItemRepository;
      }),
    };
    const service = new CartsService(
      dataSource as never,
      carts as never,
      {} as never,
    );

    await service.detail('customer-id');

    expect(restaurantRepository.findOne).toHaveBeenCalledWith({
      where: { isActive: true },
      order: { createdAt: 'ASC' },
    });
    expect(carts.findOne).toHaveBeenCalledWith({
      where: {
        customerId: 'customer-id',
        restaurantId: 'restaurant-id',
        status: 'active',
      },
    });
  });
});
