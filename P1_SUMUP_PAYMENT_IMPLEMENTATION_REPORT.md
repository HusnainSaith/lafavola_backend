# P1 SUMUP PAYMENT IMPLEMENTATION REPORT

## 1. Payment audit findings

The existing schema already separated orders, payment transactions, webhook events, refunds and internal receipts, and supported minor-unit EUR values plus pay-on-delivery. The implemented payment service was placeholder behavior: it created local pending rows without contacting a provider, recorded unverified webhook payloads and approved refunds without provider synchronization or concurrency protection.

## 2. Stripe-specific remnants found

| Existing element | Neutral? | Reused? | SumUp treatment |
|---|---:|---:|---|
| `payment_transactions` and minor-unit amount | Yes | Yes | Retained as aggregate |
| `provider_payment_intent_id` / `provider_charge_id` | No | Compatibility only | New neutral checkout/transaction columns |
| Provider check/defaults containing `stripe` | No | Historical data retained | Constraint expanded by migration 19 |
| Saved Stripe payment-method endpoints | No | No | Removed from active payment controller |
| `payment_webhook_events` | Mostly | Yes | Verified SumUp checkout-state keys |
| Refund and receipt tables | Yes | Yes | Locking, provider execution and uniqueness completed |
| Empty Stripe integration stubs | No | No | Left unregistered for historical compatibility |

No historical migration was changed or deleted.

## 3. SumUp architecture

Payment business logic depends on `PaymentProviderPort`. `SumUpPaymentProvider` is the only active adapter and returns normalized checkout/refund models rather than raw provider objects. It uses a small typed native-fetch adapter, avoiding another HTTP dependency.

## 4. Authentication approach

The backend uses a SumUp API key in the Bearer authorization header, appropriate for a direct single-merchant integration. The key is read only inside the adapter and never returned or logged. This follows SumUp's official [API-key guidance](https://developer.sumup.com/tools/authorization/api-keys).

## 5. Checkout flow

An authenticated owner calls `POST /payments/checkouts` with an order ID and idempotency key. The service locks and loads the owned order, requires online card payment, derives the amount from `grand_total_minor`, creates a unique backend reference, and calls SumUp `POST /v0.1/checkouts`. Only normalized status, checkout ID and hosted checkout URL are returned. The official checkout shape and hosted flow are documented by [SumUp Checkouts](https://developer.sumup.com/api/checkouts/get).

## 6. Payment-state mapping

| SumUp checkout | Transaction | Order payment | Fulfillment |
|---|---|---|---|
| `PENDING` | `pending` | `pending` | remains `pending_payment` |
| `PAID` | `captured` | `paid` | `pending_payment` becomes `placed` |
| `FAILED` | `failed` | `failed` | never advanced |
| `EXPIRED` | `cancelled` | `cancelled` | never advanced |

Captured/refunded terminal state cannot be overwritten by stale non-terminal checkout updates.

## 7. Webhook verification strategy

`POST /payments/webhooks/sumup` accepts the documented `CHECKOUT_STATUS_CHANGED` payload and retrieves the checkout from SumUp. It verifies checkout ID association, backend reference, merchant code, integer-equivalent amount and EUR currency before applying state. It does not invent an HMAC signature. Unknown event types are ignored for forward compatibility, following SumUp's [webhook guidance](https://developer.sumup.com/online-payments/webhooks).

## 8. Idempotency behavior

Checkout requests are unique per order/idempotency key and bind a SHA-256 material-request hash. Verified webhook/refresh states use `checkout-id:normalized-status`; duplicate deliveries cannot create another receipt, transition or outbox event. Unique provider checkout/reference/transaction indexes reinforce this at the database layer.

## 9. Refund behavior

Customers may request full or partial refunds only for their owned order and a backend-selected captured SumUp transaction. Administrators execute the provider refund. Remaining value is recalculated while the payment row is locked; cumulative refunds cannot exceed the captured amount. Provider calls use the current official merchant transaction refund endpoint from [SumUp Transactions](https://developer.sumup.com/api/transactions). Partial and full completion map to `partially_refunded` and `refunded`; fulfillment status is unchanged.

## 10. Receipt behavior

A verified capture creates one internal receipt per payment transaction from trusted order totals, tax, payment method and item snapshots. No PAN, CVV or card credential data is stored. Provider receipt retrieval is optional and the internal receipt does not depend on it.

## 11. Pay-on-delivery behavior

Cash remains provider `cash`; physical card collection remains `external_terminal`. Both are admin-collected, lock-protected and produce an internal receipt. They never call the SumUp online Checkout API. Card-present reader APIs were intentionally not implemented.

## 12. Migration 19 changes

`1700000000019-AddSumUpPaymentIntegrity` safely expands provider constraints and adds `provider_checkout_id`, `checkout_reference`, `provider_transaction_id`, `request_hash`, refund idempotency, and unique indexes for provider identifiers and one receipt per transaction. Existing 18 migrations are unchanged.

## 13. Security controls

- Provider credentials and authorization headers stay inside the adapter.
- Client-supplied amounts and transaction IDs are not accepted.
- Webhook bodies are never trusted as payment proof.
- Merchant, reference, amount and currency are verified.
- Provider errors are mapped to sanitized 502/503 responses.
- Payment ownership and admin refund/collection roles are enforced.
- Refund failure cannot falsely mark a payment refunded.

## 14. Swagger changes

Payment routes now document checkout creation, owned payment status/refresh, SumUp webhook receipt and pay-on-delivery collection with DTO runtime schemas and safe response fields. Refund routes document request, owned order/status access and admin approval. Secrets and raw provider responses are absent.

## 15. Tests added

Provider unit tests cover exact EUR conversion, create payload/merchant/reference, retrieval mapping, official refund endpoint and transport-error sanitization. PostgreSQL tests cover verified paid-state transition, duplicate webhook suppression, one receipt, one outbox transition, concurrent over-refund prevention and provider refund failure persistence. Environment validation and fresh migration counts were extended.

## 16. Dependencies added/removed

No payment dependency was added. Native `fetch` is used as a narrow typed HTTP boundary; no Stripe or overlapping HTTP library was introduced or upgraded.

## 17. Environment variables

`SUMUP_ENABLED`, `SUMUP_API_BASE_URL`, `SUMUP_API_KEY`, `SUMUP_MERCHANT_CODE`, `SUMUP_CURRENCY`, `SUMUP_RETURN_URL`, `SUMUP_HOSTED_CHECKOUT_ENABLED`, `SUMUP_REQUEST_TIMEOUT_MS`, and optional-test flag `RUN_SUMUP_TESTS` were documented in `.env.example` and `.env.test.example`. API keys and the merchant code are obtained from the SumUp Dashboard/sandbox; no real secret was written.

## 18. Files changed

Material changes are in `src/integrations/sumup`, the payments/refunds modules, payment/refund entities and DTOs, migration 19, environment validation/examples, database/unit tests, `package.json`, and `REQUIREMENTS_TRACEABILITY.md`. The developer's `.env` was not changed.

## 19. Known limitations

- No SumUp sandbox credentials were available, so ordinary tests use a fake provider.
- Webhook verification is synchronous to guarantee verified state before acknowledgement; production ingress should monitor latency and may later persist/queue verification if traffic warrants it.
- A network timeout after SumUp accepts checkout creation can leave reconciliation ambiguity. The stable checkout reference limits the recovery domain, but a scheduled reconciliation job should resolve it.
- Provider receipt URLs/details are not fetched; the backend generates its own authoritative receipt.
- Refund completion is treated as accepted by the refund endpoint; production reconciliation should also inspect transaction refund events.
- Existing dormant Stripe files and legacy columns remain for safe historical compatibility and are not registered in the active flow.

## 20. Remaining live-chat/push work

Managed live chat and push notification providers remain intentionally untouched. Production payment deployment still requires a SumUp sandbox pass, live API key/merchant configuration, reachable HTTPS webhook URL, operational reconciliation and alerting.

## Validation

- `npm run format`: PASS
- `npm run lint:check`: PASS
- `npm run build`: PASS
- `npm test -- --runInBand`: PASS — 8 suites and 55 tests passed; 4 opt-in database suites skipped by the default command
- `npm run test:e2e -- --runInBand`: PASS — 1 suite and 2 tests
- PostgreSQL payment tests: PASS — 3 tests including duplicate capture and concurrent/failing refunds
- Fresh migrations: PASS — all 19 migrations applied to guarded `lafavola_test`; the second run reported no pending migrations
- SumUp sandbox smoke tests: SKIPPED — no sandbox credentials were available

This slice does not claim the entire backend is production-ready.
