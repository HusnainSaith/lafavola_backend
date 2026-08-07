export interface OrderPricingSnapshot {
  menuVersion?: string;
  currency: 'EUR';
  subtotalMinor: number;
  optionChargesMinor: number;
  promotionDiscountMinor: number;
  couponDiscountMinor: number;
  loyaltyDiscountMinor: number;
  deliveryFeeMinor: number;
  taxMinor: number;
  grandTotalMinor: number;
}
