import { BadRequestException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { AdminPosService } from '../../src/modules/admin-pos/admin-pos.service';
import { CreatePosOrderDto } from '../../src/modules/admin-pos/dto/create-pos-order.dto';

describe('admin POS contract', () => {
  const base = {
    orderType: 'dine_in',
    paymentMethod: 'cash',
    idempotencyKey: 'pos-order-1',
    items: [
      {
        menuItemId: '11111111-1111-4111-8111-111111111111',
        sizeId: '22222222-2222-4222-8222-222222222222',
        quantity: 1,
      },
    ],
  };

  it('requires a table label for dine-in orders', async () => {
    const dto = plainToInstance(CreatePosOrderDto, base);
    const errors = await validate(dto);
    expect(errors.some((error) => error.property === 'tableLabel')).toBe(true);
  });

  it('accepts a complete takeaway order', async () => {
    const dto = plainToInstance(CreatePosOrderDto, {
      ...base,
      orderType: 'takeaway',
    });
    expect(await validate(dto)).toHaveLength(0);
  });

  it('rejects a table label on takeaway before accessing persistence', async () => {
    const service = new AdminPosService(
      undefined as never,
      undefined as never,
      undefined as never,
      undefined as never,
      undefined as never,
    );
    await expect(
      service.createOrder('actor', {
        ...base,
        orderType: 'takeaway',
        tableLabel: '12',
      } as CreatePosOrderDto),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
