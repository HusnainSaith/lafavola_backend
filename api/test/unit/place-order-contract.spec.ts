import { OrdersController } from '../../src/modules/orders/orders.controller';
import { PaymentMethodType } from '../../src/modules/payments/enums/payment-method-type.enum';

describe('customer place-order route contract', () => {
  it('delegates to the authoritative checkout transaction', async () => {
    const checkout = {
      checkout: jest.fn().mockResolvedValue({ orderId: 'order-id' }),
    };
    const controller = new OrdersController({} as never, checkout as never);
    const dto = {
      cartId: 'f7c47120-e59a-4a76-8a2a-a1d5418539cf',
      orderType: 'pickup' as const,
      paymentMethod: PaymentMethodType.CASH,
      idempotencyKey: 'mobile-order-1',
    };

    await expect(
      controller.placeOrder({ id: 'customer-id' } as never, dto),
    ).resolves.toEqual({ orderId: 'order-id' });
    expect(checkout.checkout).toHaveBeenCalledWith('customer-id', dto);
  });
});
