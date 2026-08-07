import { PaymentMethodType } from '../enums/payment-method-type.enum';

export interface CreateProviderPaymentInput {
  orderId: string;
  customerId?: string;
  amountMinor: number;
  currency: 'EUR';
  paymentMethodType: PaymentMethodType;
  providerPaymentMethodId?: string;
  idempotencyKey: string;
}

export interface ProviderPaymentResult {
  providerPaymentIntentId?: string;
  providerChargeId?: string;
  clientSecret?: string;
  status: string;
}

export interface PaymentProviderPort {
  createPayment(
    input: CreateProviderPaymentInput,
  ): Promise<ProviderPaymentResult>;
  refund(
    providerPaymentIntentId: string,
    amountMinor: number,
    idempotencyKey: string,
  ): Promise<string>;
}
