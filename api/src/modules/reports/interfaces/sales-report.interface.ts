export interface SalesReportSummary {
  totalOrders: number;
  deliveredOrders: number;
  cancelledOrders: number;
  grossRevenueMinor: number;
  discountsMinor: number;
  refundsMinor: number;
  deliveryFeesMinor: number;
  taxMinor: number;
  netRevenueMinor: number;
  averageOrderValueMinor: number;
}

export interface PopularItemMetric {
  menuItemId?: string;
  itemName: string;
  quantitySold: number;
  revenueMinor: number;
}
