# Final Requirements Traceability

Statuses are based on current source and executed automated validation. The only statuses used are `PASS`, `CLIENT DECISION REQUIRED`, and `PROVIDER CREDENTIAL TEST PENDING`.

| Requirement | Status | Evidence / remaining gap |
|---|---|---|
| Authentication | PASS | Customer-only registration, verification, account-state checks, hashed one-time tokens, rotating hashed refresh sessions and regression tests. |
| Customer profile | PASS | Ownership-scoped profile/preferences APIs and safe saved-payment-reference list/default/archive operations are implemented. |
| Addresses | PASS | Ownership-scoped CRUD and one-active-default database constraint. |
| Menu | PASS | Active/available joined public catalog with pagination. |
| Pizza categories | PASS | Public reads and admin mutations exist. |
| Standard pizza | PASS | Active item/size selection and authoritative server pricing. |
| Modified pizza | PASS | Item/group membership, required/min/max, removal and incompatibility validation. |
| Build-your-own pizza | PASS | Builder group and topping constraints are server validated. |
| Cart | PASS | Ownership, atomic multi-add, repricing and quantity mutation. Additional cart-change/checkout race coverage remains desirable. |
| Promotions | CLIENT DECISION REQUIRED | Percentage/fixed/free-delivery eligibility and deterministic stacking pass. BOGO, free-item, bundle, student and custom semantics are undefined. |
| Deals | CLIENT DECISION REQUIRED | Generic configured promotions pass; family-combo composition and pricing are undefined. |
| Coupons | PASS | Window/minimum/caps/limits, locking and atomic redemption are implemented. |
| Online payments | PROVIDER CREDENTIAL TEST PENDING | SumUp adapter and authoritative verification exist; sandbox credentials/webhook reachability were not tested. |
| Pay on delivery | PASS | Cash/card-on-delivery create `collection_pending`; assigned-driver/admin collection is locked, amount-authoritative and receipt-producing. Concurrent duplicate collection is database-tested. |
| Digital receipts | PASS | Unique receipt issuance exists for verified or collected payments. |
| Delivery | PASS | Locked assignment plus assigned-driver/admin transition matrix covers accept, pickup, en-route, arriving, delivery, failure and cancellation; order history, tracking and outbox writes are atomic. |
| ETA | PASS | Checkout derives the estimate from `restaurant.defaultDeliveryMinutes`; tracking accepts remaining-minute updates. |
| Live tracking | PROVIDER CREDENTIAL TEST PENDING | Persisted ownership-scoped tracking and delivery events pass; the AppSync customer stream requires credential-backed verification. |
| Notifications | PASS | In-app records, preferences, outbox, delivery records and token lifecycle exist. |
| Search | PASS | Database-side name search. |
| Filters | PASS | Category, dietary, ingredient, price, availability and sort filters. |
| Favorites | PASS | Ownership-scoped APIs, uniqueness, and favorite-to-cart quick reorder with current server validation are implemented. |
| Order history | PASS | Ownership-scoped pagination/detail. |
| Reorder | PASS | Availability-aware atomic batch reorder. |
| Customer support | PASS | Ownership-scoped ticket and message history. |
| Live chat | PROVIDER CREDENTIAL TEST PENDING | Durable outbox/AppSync boundary, claims and unread state pass DB tests; real AppSync needs credential smoke. |
| FAQ | PASS | Public reads and admin mutations. |
| Refunds | PROVIDER CREDENTIAL TEST PENDING | Locked balance checks and SumUp refund adapter pass mocked/database tests; sandbox smoke is absent. |
| Admin menu management | PASS | Role-protected category/menu/option APIs exist. |
| Ingredient management | PASS | Role-protected CRUD exists. |
| Pricing management | PASS | Size/option/ingredient pricing is admin-managed in minor units. |
| Order management | PASS | Locked transition matrix and history/outbox writes. |
| Delivery management | PASS | Admin assignment/inspection and explicit driver lifecycle are implemented with ownership and concurrency tests. |
| Customer management | PASS | Identity administration plus ownership-scoped privacy request creation and technical fulfillment are implemented. |
| Sales reports | PASS | Gross/recognized/refunds/net/discount/tax/fees/count/AOV aggregates are date- and restaurant-scoped and fixture-tested. |
| Daily revenue | PASS | A zero-filled daily API reports recognized revenue, refunds and net; live aggregation avoids an undefined snapshot schedule. |
| Popular items | PASS | Delivered/closed quantity ranking query exists. |
| Security | PASS | Deny-by-default auth/RBAC, strict role matching, ownership, Helmet, CORS validation, throttling and safe error mapping. Customer-to-admin report denial is HTTP/database-tested. |
| Privacy | CLIENT DECISION REQUIRED | Technical export, restriction and anonymization pass; legal retention, SLA, rectification and exact erasure boundaries require policy decisions. |
| AWS storage | PROVIDER CREDENTIAL TEST PENDING | Presign/finalize/ownership/delete boundary exists; real S3 smoke was not run. |
| Email | PROVIDER CREDENTIAL TEST PENDING | Nodemailer adapter and outbox mail exist; real SMTP was not tested. |
| Push | PROVIDER CREDENTIAL TEST PENDING | Firebase Admin adapter, idempotency and invalid-token retirement exist; real FCM was not tested. |
| SumUp | PROVIDER CREDENTIAL TEST PENDING | Contract and PostgreSQL payment/refund tests pass; real sandbox smoke was not run. |
| Swagger | PASS | Reproducible OpenAPI contains all 151 controller operations; final route inventory records response-contract refinement debt explicitly. |
| Operational functional behavior | PASS | Health/readiness, graceful shutdown and a durable separate outbox worker exist; undefined schedules remain intentionally inactive. |

## Final conclusion

All credential-independent behavior with defined rules is implemented and automated gates pass. The scope is **functionally complete for defined rules, with client decisions required** for BOGO, family combo, student discount, loyalty economics and legal retention. Real-provider and infrastructure verification remains deployment-dependent. See `CLIENT_DECISIONS_REQUIRED.md` and `PRODUCTION_READINESS.md`.
