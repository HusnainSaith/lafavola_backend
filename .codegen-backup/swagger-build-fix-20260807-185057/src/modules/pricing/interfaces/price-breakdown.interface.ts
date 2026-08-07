import { MoneyBreakdown } from '../../../common/interfaces/money.interface';

export interface PriceBreakdown extends MoneyBreakdown {
  appliedPromotionIds: string[];
  appliedCouponId?: string;
}
