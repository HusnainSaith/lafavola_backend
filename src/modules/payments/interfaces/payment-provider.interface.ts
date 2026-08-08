export const PAYMENT_PROVIDER = Symbol('PAYMENT_PROVIDER');

export type ProviderPaymentStatus =
  'pending' | 'captured' | 'failed' | 'cancelled';

export interface CreateProviderCheckoutInput {
  checkoutReference: string;
  amountMinor: number;
  currency: 'EUR';
  description: string;
}

export interface ProviderCheckout {
  checkoutId: string;
  checkoutReference: string;
  merchantCode: string;
  amountMinor: number;
  currency: 'EUR';
  status: ProviderPaymentStatus;
  hostedCheckoutUrl?: string;
  transactionId?: string;
  transactionCode?: string;
}

export interface ProviderRefundResult {
  providerRefundId?: string;
  status: 'refunded' | 'processing';
}

export interface PaymentProviderPort {
  createCheckout(input: CreateProviderCheckoutInput): Promise<ProviderCheckout>;
  getCheckout(checkoutId: string): Promise<ProviderCheckout>;
  deactivateCheckout(checkoutId: string): Promise<void>;
  refundPayment(
    providerTransactionId: string,
    amountMinor: number,
  ): Promise<ProviderRefundResult>;
}
