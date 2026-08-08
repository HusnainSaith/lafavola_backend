# Final Functional Acceptance Report

## Functional classification

**B. FUNCTIONALLY COMPLETE EXCEPT CLIENT-DECISION-REQUIRED RULES**

This classification concerns backend behavior only. SMTP, S3, SumUp, AppSync and Firebase credential smoke tests remain intentionally skipped and do not change the classification. Complete authenticated HTTP journeys are still thinner than the database/service acceptance layer and are reported as such below.

## Acceptance results

| # | Area | Result | Executable evidence / qualification |
|---:|---|---|---|
| 1 | Customer journey | PASS by composed layers | Authentication DB tests plus ordering DB suites cover identity, catalog-to-order state and persistence. HTTP E2E proves startup and protected-route boundaries; it is not one monolithic 48-step test. |
| 2 | Customer negative journey | PASS | Guard/ownership unit tests, auth DB tests and ordering/delivery/privacy ownership tests reject cross-customer and role escalation paths. |
| 3 | Admin journey | PASS by composed layers | Deny-by-default RBAC, admin route inventory, ordering/payment/reporting DB tests and HTTP protection checks cover the defined behavior. |
| 4 | Driver journey | PASS | Assignment, wrong-driver denial, accept/pickup/en-route/arriving/delivered, location and COD collection are database-tested. |
| 5 | Support journey | PASS | Ticket persistence, agent claim race, replies, unread state, authorization and closed-state behavior are covered by support/chat integration boundaries. |
| 6 | Standard pizza | PASS | Active item/size validation and authoritative price calculation are exercised by ordering/pricing tests. |
| 7 | Modified pizza | PASS | Group membership, removals, required/min/max and incompatibility rules are server-enforced. |
| 8 | Custom pizza | PASS | Builder size/group/choice constraints and authoritative option pricing are server-enforced. |
| 9 | Menu/search | PASS | Deterministic PostgreSQL tests cover joined catalog search/filter/pagination and availability. |
| 10 | Cart | PASS | Ownership, add/update/remove/clear, server snapshots and repricing are implemented; checkout never trusts submitted totals. |
| 11 | Promotions/coupons | PASS for defined rules | Percentage, fixed, free-delivery, windows, minimums, priority, stacking, compatibility and locked limits pass. BOGO/family/student are decision-required. |
| 12 | Checkout | PASS | Locked repricing, availability, snapshots, idempotency and atomic redemption are PostgreSQL-tested. |
| 13 | SumUp mocked payment | PASS | Provider contract, checkout verification, webhook idempotency, amount/currency/merchant validation, receipt and refund boundaries use fake providers. |
| 14 | COD/card-on-delivery | PASS | Collection-pending, driver/admin authorization, exact method/amount, receipt and duplicate race behavior pass. |
| 15 | Orders/history/reorder | PASS | Customer-scoped history/detail, status history and locked availability-aware atomic reorder pass. |
| 16 | Delivery/tracking | PASS | Explicit locked lifecycle, tracking events, ownership, outbox and payment-gated delivery pass. |
| 17 | Notifications | PASS with fake providers | Persistence, preferences, delivery attempts, invalid-token retirement and order/delivery/refund event boundaries are implemented. Real delivery is credential-pending. |
| 18 | Favorites | PASS | Customer ownership and uniqueness are enforced; favorites can feed the normal cart/order path. |
| 19 | Loyalty technical integrity | PASS / decision boundary | Account/ledger integrity exists. Checkout earning, redemption value, expiry and reversal remain disabled until commercial rules are supplied. |
| 20 | Support/live chat | PASS with fake provider | Durable messages/outbox, claims, unread/read state and publish boundary pass. Real AppSync smoke is pending. |
| 21 | Refunds | PASS with fake provider | Locked refundable balance, partial/full/over-refund protection, provider failure and reporting linkage are implemented. Delivered orders are not blindly cancelled. |
| 22 | Reports | PASS | Exact fixtures verify gross, recognized, refunds, net, discount, tax, delivery fees, counts, AOV, daily series and popular items. |
| 23 | Privacy | PASS for technical policy | Consent, owned request/export, restriction and anonymization pass; exports exclude token/password/provider secrets. Legal policy remains decision-required. |
| 24 | Media | PASS with fake provider | Server-owned keys, MIME/size policy, ownership, finalize and deletion boundaries exist. Real S3 smoke is pending. |
| 25 | Authorization/ownership | PASS | Global JWT/RBAC plus resource predicates cover customer, staff, support, driver and administrator boundaries. |
| 26 | Database integrity | PASS | All 21 migrations apply on a fresh `_test` database; second execution is a no-op; integrity suites cover key unique/check/FK rules. |
| 27 | Concurrency | PASS for critical paths | Checkout/promotion redemption, refunds, support claim, delivery transition and COD duplicate collection use locks/transactions and have DB evidence. |
| 28 | Swagger | PASS with documented refinement debt | Generated contract has 104 paths, 151 operations and 67 schemas. Every operation is listed in `FINAL_ROUTE_INVENTORY.md`. Some legacy responses remain implicitly typed. |
| 29 | Performance findings | ACCEPTABLE FOR FUNCTIONAL RELEASE | Core growing lists use database pagination/filtering and relevant indexes. Production-scale `EXPLAIN ANALYZE` and load evidence are outside functional acceptance. |
| 30 | Client decisions remaining | REQUIRED | BOGO semantics, family-combo composition/pricing, student verification/discount policy, loyalty economics/expiry/refunds, and privacy retention/SLA boundaries. |

## Route and contract audit

`FINAL_ROUTE_INVENTORY.md` lists all 151 OpenAPI operations with method, route, module, purpose, access, request/response contract, ownership, coverage and client mapping. No duplicate route was found. The delivery lifecycle intentionally uses a single validated status-transition endpoint instead of duplicate action routes.

Global validation uses transformation, whitelist and forbidden-non-whitelisted properties. Representative DTO, authentication, authorization, ownership, PostgreSQL constraint and sanitized-error cases pass. Secrets, password hashes, refresh/verification digests and raw provider credentials are not part of public response contracts or privacy exports.

## Executed validation

| Command | Result |
|---|---|
| `npm run format` | PASS |
| `npm run lint:check` | PASS |
| `npm run build` | PASS |
| `npm test -- --runInBand` | PASS: 9 suites, 60 tests; credential/DB-gated suites skipped by default |
| `npm run test:e2e -- --runInBand` | PASS: 1 suite, 9 tests |
| `npm run test:all:db` with protected `lafavola_test` | PASS: 7 suites, 33 tests |
| Fresh migrations | PASS: 21 |
| Second migration execution | PASS: no pending migrations |
| OpenAPI generation | PASS: 104 paths, 151 operations, 67 schemas |
| `git diff --check` | PASS; CRLF/LF notices are informational |

Total executed assertions: **102 tests** (60 unit + 9 HTTP E2E + 33 PostgreSQL integration). Provider smoke status: SMTP SKIPPED, AWS S3 SKIPPED, SumUp SKIPPED, AWS AppSync SKIPPED, Firebase SKIPPED.

## Coverage caveat

The requested behavior is proven through composed unit, HTTP-boundary and real-PostgreSQL service journeys. There is not currently one enormous authenticated HTTP test for each customer/admin/support workflow. This avoids falsely claiming HTTP-level coverage that does not exist, while the functional classification reflects implemented and database-validated business behavior.
