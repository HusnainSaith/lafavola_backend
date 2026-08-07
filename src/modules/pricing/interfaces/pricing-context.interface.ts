export interface PricingSelection {
  optionGroupId?: string;
  optionChoiceId?: string;
  ingredientId?: string;
  action: 'add' | 'remove' | 'replace';
  quantity: number;
}

export interface PricingContext {
  restaurantId: string;
  customerId?: string;
  menuItemId: string;
  menuItemSizeId?: string;
  quantity: number;
  selections: PricingSelection[];
  couponCode?: string;
}
