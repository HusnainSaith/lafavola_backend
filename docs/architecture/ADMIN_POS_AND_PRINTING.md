# Admin POS and thermal-printing architecture

## Data and API boundary

`orders.order_type` adds `dine_in` and `takeaway`. Walk-in metadata is stored as
snapshots on the order: table label, customer name/phone and creating staff user.
The existing order number remains the operational identifier. The existing
payment transaction and receipt tables remain the payment source of truth.

The authenticated admin contract is:

- `GET /api/v1/admin/pos/catalog`
- `POST /api/v1/admin/pos/orders`
- `POST /api/v1/admin/pos/orders/{id}/collect`
- `GET /api/v1/admin/pos/orders/{id}/receipt`
- `GET /api/v1/admin/pos/receipts` (all paid restaurant orders)

Creation snapshots names/options and uses `PricingService` plus
`OrderTotalsService`. Collection delegates to the existing payment service after
restaurant ownership checks. Receipt reads join immutable order-item snapshots,
payment receipt, restaurant identity and payment method.

## Flutter boundary

The `features/pos` slice owns POS catalogue/cart/checkout state. It uses Riverpod
for the cart/session and the existing Dio client for authenticated APIs.
`features/printing` owns printer discovery, saved selection and ESC/POS rendering.
The order/payment state is persisted by the backend; the printer is a disposable
output transport and cannot change backend state.

## Receipt layout

The renderer produces a deterministic 58 mm or 80 mm ticket with restaurant
identity, order/receipt number, service mode/table, timestamp, item/option lines,
subtotal, discounts, tax, total, payment method and a non-fiscal notice. A print
preview is always shown before sending bytes to a selected printer.

## Security and operability

- Every POS query resolves the active staff membership and its restaurant.
- Idempotency protects retries from mobile/network interruptions.
- No printer address, receipt body, token or personal data is logged.
- Printer failures are local and retryable; database transactions are complete
  before printing begins.
- Physical printer compatibility remains a hardware acceptance test using the
  client's exact printer model and paper width.
