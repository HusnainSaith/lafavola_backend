export interface PriceBreakdown {
  currency: 'EUR';

  basePriceMinor: number;
  optionAdjustmentsMinor: number;
  unitPriceMinor: number;

  quantity: number;
  lineTotalMinor: number;

  subtotalMinor: number;
  optionChargesMinor: number;

  discountMinor: number;
  loyaltyDiscountMinor: number;
  deliveryFeeMinor: number;
  taxMinor: number;

  grandTotalMinor: number;

  appliedPromotionIds: string[];
}
