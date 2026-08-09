import { OrderTotalsService } from '../../src/modules/pricing/order-totals.service';

describe('OrderTotalsService', () => {
  const service = new OrderTotalsService();
  const calculate = (
    overrides: Partial<Parameters<typeof service.calculate>[0]> = {},
  ) =>
    service.calculate({
      subtotalMinor: 1_000,
      optionChargesMinor: 200,
      deliveryFeeMinor: 300,
      promotionDiscountMinor: 0,
      couponDiscountMinor: 0,
      loyaltyDiscountMinor: 0,
      deliveryDiscountMinor: 0,
      taxRateBasisPoints: 1_000,
      taxExcluded: true,
      ...overrides,
    });

  it.each([
    ['no discount', {}, 1_650],
    ['promotion only', { promotionDiscountMinor: 100 }, 1_540],
    ['coupon only', { couponDiscountMinor: 200 }, 1_430],
    [
      'promotion and coupon',
      { promotionDiscountMinor: 100, couponDiscountMinor: 200 },
      1_320,
    ],
    ['free delivery', { deliveryDiscountMinor: 300 }, 1_320],
    ['quantity is reflected in subtotal', { subtotalMinor: 3_000 }, 3_850],
    [
      'expensive customization',
      { subtotalMinor: 20_000, optionChargesMinor: 8_000 },
      31_130,
    ],
  ])('%s', (_name, overrides, expected) => {
    expect(calculate(overrides).grandTotalMinor).toBe(expected);
  });

  it('never produces a negative grand total', () => {
    const result = calculate({
      promotionDiscountMinor: 50_000,
      couponDiscountMinor: 50_000,
      deliveryDiscountMinor: 50_000,
    });
    expect(result.grandTotalMinor).toBe(0);
    expect(result.deliveryDiscountMinor).toBe(300);
  });
});
