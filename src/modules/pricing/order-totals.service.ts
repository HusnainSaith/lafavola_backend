import { Injectable } from '@nestjs/common';

export interface OrderTotalsInput {
  subtotalMinor: number;
  optionChargesMinor: number;
  deliveryFeeMinor: number;
  promotionDiscountMinor: number;
  couponDiscountMinor: number;
  loyaltyDiscountMinor: number;
  deliveryDiscountMinor: number;
  taxRateBasisPoints: number;
  taxExcluded: boolean;
}

@Injectable()
export class OrderTotalsService {
  calculate(input: OrderTotalsInput) {
    const merchandiseTotalMinor =
      input.subtotalMinor + input.optionChargesMinor;
    const deliveryDiscountMinor = Math.min(
      input.deliveryFeeMinor,
      input.deliveryDiscountMinor,
    );
    const taxableMinor = Math.max(
      0,
      merchandiseTotalMinor +
        input.deliveryFeeMinor -
        input.promotionDiscountMinor -
        input.couponDiscountMinor -
        input.loyaltyDiscountMinor -
        deliveryDiscountMinor,
    );
    const taxMinor = input.taxExcluded
      ? Math.round((taxableMinor * input.taxRateBasisPoints) / 10_000)
      : 0;
    const grandTotalMinor = Math.max(0, taxableMinor + taxMinor);
    return {
      ...input,
      deliveryDiscountMinor,
      merchandiseTotalMinor,
      taxableMinor,
      taxMinor,
      grandTotalMinor,
    };
  }
}
