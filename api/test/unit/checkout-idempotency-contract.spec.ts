import { ConflictException } from '@nestjs/common';
import { createHash } from 'crypto';
import { IdempotencyKey } from '../../src/modules/audit/entities/idempotency-key.entity';
import { CheckoutService } from '../../src/modules/checkout/checkout.service';
import { CheckoutDto } from '../../src/modules/checkout/dto/checkout.dto';

describe('checkout idempotency boundary', () => {
  const customerId = '10000000-0000-4000-8000-000000000001';
  const dto: CheckoutDto = {
    cartId: '20000000-0000-4000-8000-000000000001',
    orderType: 'pickup',
    paymentMethod: 'cash' as CheckoutDto['paymentMethod'],
    idempotencyKey: 'checkout-replay-safe-contract',
  };

  const requestHash = createHash('sha256')
    .update(
      JSON.stringify({
        cartId: dto.cartId,
        orderType: dto.orderType,
        deliveryAddressId: null,
        paymentMethod: dto.paymentMethod,
        savedPaymentMethodId: null,
        couponCode: null,
        customerNote: null,
        deliveryInstructions: null,
        scheduledFor: null,
      }),
    )
    .digest('hex');

  const buildService = (previous: Partial<IdempotencyKey>) => {
    const idempotencyRepository = {
      findOne: jest.fn().mockResolvedValue(previous),
    };
    const dataSource = {
      getRepository: jest.fn((entity) => {
        if (entity === IdempotencyKey) return idempotencyRepository;
        throw new Error(`Unexpected repository ${String(entity)}`);
      }),
      transaction: jest.fn(),
    };
    const carts = { detailById: jest.fn() };
    return {
      service: new CheckoutService(
        dataSource as never,
        carts as never,
        {} as never,
        {} as never,
        {} as never,
        {} as never,
        {} as never,
      ),
      carts,
      dataSource,
    };
  };

  it('replays an authoritative response before reading or mutating the cart', async () => {
    const responseBody = { orderId: 'existing-order', status: 'placed' };
    const { service, carts, dataSource } = buildService({
      requestHash,
      responseBody,
    });

    await expect(service.checkout(customerId, dto)).resolves.toBe(responseBody);
    expect(carts.detailById).not.toHaveBeenCalled();
    expect(dataSource.transaction).not.toHaveBeenCalled();
  });

  it('rejects same-key different-body conflicts before cart access', async () => {
    const { service, carts, dataSource } = buildService({
      requestHash: 'different-request-hash',
    });

    await expect(service.checkout(customerId, dto)).rejects.toThrow(
      ConflictException,
    );
    expect(carts.detailById).not.toHaveBeenCalled();
    expect(dataSource.transaction).not.toHaveBeenCalled();
  });
});
