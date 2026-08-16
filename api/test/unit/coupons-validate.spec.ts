import { BadRequestException } from '@nestjs/common';
import { Coupon } from '../../src/modules/coupons/entities/coupon.entity';
import { CouponRedemption } from '../../src/modules/coupons/entities/coupon-redemption.entity';
import { Restaurant } from '../../src/modules/restaurants/entities/restaurant.entity';
import { CouponsService } from '../../src/modules/coupons/coupons.service';

describe('CouponsService.validate (customer coupon preview)', () => {
  function couponRepo(getOne: jest.Mock) {
    return {
      createQueryBuilder: jest.fn(() => ({
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getOne,
      })),
    };
  }

  function buildService(coupon: Coupon | null) {
    const restaurantRepository = {
      findOne: jest.fn().mockResolvedValue({ id: 'rest-1' }),
    };
    const dataSource = {
      getRepository: jest.fn((entity: unknown) => {
        if (entity === Coupon)
          return couponRepo(jest.fn().mockResolvedValue(coupon));
        if (entity === Restaurant) return restaurantRepository;
        throw new Error('unexpected repository request');
      }),
    } as never;
    return {
      service: new CouponsService({} as never, dataSource),
      restaurantRepository,
    };
  }

  const baseCoupon = {
    id: 'coupon-1',
    restaurantId: 'rest-1',
    code: 'WELCOME10',
    discountType: 'percentage',
    discountValue: 10,
    minOrderMinor: 0,
    maxDiscountMinor: undefined,
  } as unknown as Coupon;

  it('returns the percentage discount for the provided subtotal', async () => {
    const { service } = buildService({
      ...baseCoupon,
      discountValue: 10,
      maxDiscountMinor: undefined,
    });
    const result = await service.validate({
      code: 'welcome10',
      subtotalMinor: 2000,
    });
    expect(result.valid).toBe(true);
    expect(result.applies).toBe(true);
    expect(result.discountMinor).toBe(200);
    expect(result.code).toBe('WELCOME10');
  });

  it('caps a percentage discount at the maximum allowed', async () => {
    const { service } = buildService({
      ...baseCoupon,
      discountValue: 10,
      maxDiscountMinor: 150,
    });
    const result = await service.validate({
      code: 'welcome10',
      subtotalMinor: 2000,
    });
    expect(result.discountMinor).toBe(150);
  });

  it('returns zero discount and applies=false below the minimum order', async () => {
    const { service } = buildService({
      ...baseCoupon,
      discountType: 'fixed_amount',
      discountValue: 500,
      minOrderMinor: 1000,
    });
    const result = await service.validate({
      code: 'welcome10',
      subtotalMinor: 900,
    });
    expect(result.applies).toBe(false);
    expect(result.discountMinor).toBe(0);
  });

  it('falls back to the active restaurant when restaurantId is omitted', async () => {
    const { service, restaurantRepository } = buildService(baseCoupon);
    await service.validate({ code: 'welcome10', subtotalMinor: 2000 });
    expect(restaurantRepository.findOne).toHaveBeenCalledWith({
      where: { isActive: true },
      order: { createdAt: 'ASC' },
    });
  });

  it('rejects an invalid or expired coupon code', async () => {
    const { service } = buildService(null);
    await expect(
      service.validate({ code: 'invalid', subtotalMinor: 2000 }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
describe('CouponsService.listForCustomer (customer coupon inbox)', () => {
  function serviceMocks(coupons: Coupon[], totalRows = [], customerRows = []) {
    const couponQb = {
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      getMany: jest.fn().mockResolvedValue(coupons),
    };
    const couponRepository = {
      createQueryBuilder: jest.fn(() => couponQb),
    };
    const redemptionQb = {
      select: jest.fn().mockReturnThis(),
      addSelect: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      groupBy: jest.fn().mockReturnThis(),
      getRawMany: jest
        .fn()
        .mockResolvedValueOnce(totalRows)
        .mockResolvedValueOnce(customerRows),
    };
    const redemptionRepository = {
      createQueryBuilder: jest.fn(() => redemptionQb),
    };
    const restaurantRepository = {
      findOne: jest.fn().mockResolvedValue({ id: 'rest-1' }),
    };
    const dataSource = {
      getRepository: jest.fn((entity: unknown) => {
        if (entity === Coupon) return couponRepository;
        if (entity === CouponRedemption) return redemptionRepository;
        if (entity === Restaurant) return restaurantRepository;
        throw new Error('unexpected repository request');
      }),
    } as never;
    return { service: new CouponsService({} as never, dataSource) };
  }

  it('returns redeemable coupons for the customer', async () => {
    const couponA = {
      id: 'coupon-a',
      code: 'HELLO',
      discountType: 'fixed_amount',
      discountValue: 500,
      minOrderMinor: 1000,
    } as unknown as Coupon;
    const { service } = serviceMocks([couponA]);
    const result = await service.listForCustomer('cust-1');
    expect(result).toHaveLength(1);
    expect(result[0]).toEqual(
      expect.objectContaining({ id: 'coupon-a', code: 'HELLO' }),
    );
  });

  it('excludes coupons exhausted by the per-customer usage limit', async () => {
    const couponA = {
      id: 'coupon-a',
      code: 'OK',
      discountType: 'percentage',
      discountValue: 10,
      minOrderMinor: 0,
    } as unknown as Coupon;
    const couponB = {
      id: 'coupon-b',
      code: 'USED',
      discountType: 'percentage',
      discountValue: 10,
      minOrderMinor: 0,
      perCustomerLimit: 1,
    } as unknown as Coupon;
    const customerRows = [{ couponId: 'coupon-b', count: '1' }];
    const { service } = serviceMocks([couponA, couponB], [], customerRows);
    const result = await service.listForCustomer('cust-1');
    expect(result.map((entry) => entry.code)).toEqual(['OK']);
  });

  it('returns an empty list when no coupons are active', async () => {
    const { service } = serviceMocks([]);
    const result = await service.listForCustomer('cust-1');
    expect(result).toEqual([]);
  });
});
