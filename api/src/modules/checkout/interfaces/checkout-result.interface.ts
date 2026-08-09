export interface CheckoutResult {
  orderId: string;
  orderNumber: string;
  paymentRequired: boolean;
  paymentTransactionId?: string;
  clientSecret?: string;
  estimatedDeliveryAt?: Date;
}
