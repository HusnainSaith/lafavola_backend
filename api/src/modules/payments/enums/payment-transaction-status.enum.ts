export enum PaymentTransactionStatus {
  PENDING = 'pending',
  REQUIRES_ACTION = 'requires_action',
  AUTHORIZED = 'authorized',
  CAPTURED = 'captured',
  FAILED = 'failed',
  COLLECTION_PENDING = 'collection_pending',
  CANCELLED = 'cancelled',
  PARTIALLY_REFUNDED = 'partially_refunded',
  REFUNDED = 'refunded',
}
