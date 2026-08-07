import { MoneyBreakdown } from '../../../common/interfaces/money.interface';

export interface PriceBreakdown extends MoneyBreakdown {
  basePriceMinor: number;
  optionAdjustmentsMinor: number;
  unitPriceMinor: number;
  quantity: number;
  lineTotalMinor: number;
  appliedPromotionIds: string[];
  appliedCouponId?: string;
}
