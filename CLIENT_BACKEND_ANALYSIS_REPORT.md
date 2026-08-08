# La Favola Client Requirements vs Backend Report

## 1. Executive summary

This report compares the client-supplied `pizza application.md` and the milestone image with the current NestJS/PostgreSQL backend. It distinguishes implemented backend behavior from missing application behavior, unresolved product rules, provider verification, and frontend-only scope.

### Overall backend status

**The core backend is substantially complete, but the literal client scope is not 100% complete.** Ordering, pizza configuration, authoritative pricing, checkout, orders, delivery, pay-on-delivery, reporting, privacy workflows, administration foundations, safe saved-payment-reference management, favorite quick reorder, and security are implemented. The remaining excluded or decision-blocked work is optional social login, undefined promotion types, promotion/coupon campaign timing, and loyalty/privacy policies.

Current automated evidence:

- 62 unit tests pass.
- 9 HTTP startup/readiness/auth-boundary tests pass.
- 39 PostgreSQL integration, HTTP-journey, concurrency, and Swagger route-smoke tests pass.
- All 22 migrations apply to a fresh protected test database; the second run is a no-op. Required system roles are seeded by migration, so a fresh deployment can register customers.
- OpenAPI contains 108 paths, 155 operations, and 69 schemas.
- A PostgreSQL-backed authenticated customer HTTP journey now covers registration through logout, menu/cart/checkout, orders, favorites, support, notifications, database totals, and customer-to-admin denial. A separate test invokes every documented Swagger operation and rejects any HTTP 500 response. Dedicated full-success admin/driver/support HTTP journeys remain separate follow-up coverage.

## 2. Status definitions

| Status | Meaning |
|---|---|
| COMPLETED | Implemented in the backend with source/schema evidence. |
| COMPLETED, PROVIDER TEST PENDING | Functional adapter/boundary exists, but real credentials were intentionally not exercised. |
| PARTIALLY COMPLETED | Supporting schema or service behavior exists, but the complete client-facing workflow or API is absent. |
| MISSING | Client-described backend behavior is not implemented. |
| CLIENT DECISION REQUIRED | A commercial or policy rule is too ambiguous to implement safely. |
| FRONTEND / EXTERNAL SCOPE | Primarily a mobile UI, content, store, or external communication responsibility. |

## 3. Client requirement analysis

### 3.1 Authentication and accounts

| Client feature | Status | Backend evidence / gap |
|---|---|---|
| Register with email, mobile number, and password | COMPLETED | Customer registration accepts identity credentials and prevents privilege-bearing self-registration. Email/phone uniqueness is enforced. |
| Login with existing credentials | COMPLETED | Login validates account state and issues access plus rotating refresh sessions. |
| Email verification | COMPLETED, PROVIDER TEST PENDING | Single-use hashed verification tokens and resend flow exist. Real SMTP delivery is pending credentials. |
| Phone verification | PARTIALLY COMPLETED | Database token type supports `phone_verify`, but no complete phone-verification/SMS route and provider workflow exists. The client document requires phone registration but does not explicitly require phone verification. |
| Password reset | COMPLETED, PROVIDER TEST PENDING | Request/reset routes, hashed one-time tokens, expiry and reuse prevention exist. Real mail delivery is pending. |
| Refresh and logout | COMPLETED | Refresh rotation and logout revocation are implemented and tested. |
| Google login | MISSING, OPTIONAL | Social-account schema, enum, and DTO exist, but the Google integration service is empty and no social-login route exists. The client labels this optional. |
| Apple login | MISSING, OPTIONAL | Social-account schema, enum, and DTO exist, but the Apple integration service is empty and no social-login route exists. The client labels this optional. |

### 3.2 Customer profile

| Client feature | Status | Backend evidence / gap |
|---|---|---|
| Full name, phone, email | COMPLETED | Ownership-scoped profile APIs and identity persistence exist. |
| Saved delivery addresses | COMPLETED | Customer-scoped CRUD and exactly-one-default integrity rule exist. |
| Delivery instructions | COMPLETED | Address/order delivery snapshots preserve delivery instructions. |
| Saved payment preferences | COMPLETED for existing provider references | Customer-owned safe list/default/archive APIs exist. Provider identifiers are never returned or client-created, and raw card details are not stored. Creating reusable methods remains provider-capability dependent. |
| Order history and detail | COMPLETED | Paginated owner-scoped history/detail routes exist. |
| Favorite meals | COMPLETED | Owner-scoped add/list/remove with configuration snapshots and uniqueness exist. |
| Loyalty points | CLIENT DECISION REQUIRED | Account/ledger schema exists, but earn rate, point value, eligibility, expiry, refund reversal, caps, and stacking are undefined. |
| Update personal information | COMPLETED | Profile/preferences/address update APIs exist. |

### 3.3 Menu and media

| Client feature | Status | Backend evidence / gap |
|---|---|---|
| Name, description, ingredients | COMPLETED | Joined menu/catalog model and management routes exist. |
| Small, medium, and large sizes | COMPLETED | Size codes and per-size minor-unit pricing are supported. |
| Base and extra prices | COMPLETED | Server-side size, option, and ingredient adjustments are authoritative. |
| Calories and preparation time | COMPLETED | Menu metadata supports these fields. |
| High-quality image metadata/upload | COMPLETED, PROVIDER TEST PENDING | Media metadata, presign, finalize, ownership, MIME/size/key validation, and deletion exist. Real S3/CloudFront behavior is pending credentials. Image quality/content is a client/frontend responsibility. |
| Inactive/unavailable menu suppression | COMPLETED | Public queries and checkout validate active state and availability windows. |

### 3.4 Pizza modes and customization

| Client feature | Status | Backend evidence / gap |
|---|---|---|
| Standard menu pizza | COMPLETED | Active item and size selection with authoritative base price. |
| Slightly modified pizza | COMPLETED | Additions, removals, extra cheese/toppings/crust choices, group membership, required/min/max, and incompatibility checks exist. |
| Fully customized pizza | COMPLETED | Size, dough, sauce, cheese, toppings, builder constraints, and calculated option prices exist. |
| Automatic price updates | COMPLETED (API) | Pricing endpoint and cart/checkout repricing return server-calculated totals. Live visual updates are frontend scope. |
| Cross-restaurant/inactive/wrong-group protection | COMPLETED | Configuration validation prevents invalid selections. |

### 3.5 Cart and checkout

| Client feature | Status | Backend evidence / gap |
|---|---|---|
| Add, list, increase/decrease, remove, clear | COMPLETED | Customer-owned cart mutation APIs exist. |
| Base price and option charges | COMPLETED | Names, item prices, and option prices are derived from database state. |
| Tax, delivery fee, discount, grand total | COMPLETED | Integer minor-unit calculations are shared with checkout. |
| Coupon application | COMPLETED | Eligibility, validity, limits, caps, locking, and atomic redemption exist. |
| Checkout availability validation | COMPLETED | Current restaurant/item availability is rechecked under transaction. |
| Immutable order snapshots | COMPLETED | Items, options, totals, and delivery data are snapshotted. |
| Idempotent checkout | COMPLETED | Request identity/content binding and replay behavior exist. |

### 3.6 Promotions and deals

| Client feature | Status | Backend evidence / gap |
|---|---|---|
| Percentage discount | COMPLETED | Deterministic eligibility and calculation exist. |
| Fixed discount | COMPLETED | Minimum/cap/eligibility logic exists. |
| Free delivery | COMPLETED | Supported promotion result is integrated into pricing. |
| Date windows and limited-time/weekend offers | COMPLETED when configured | Validity windows and deterministic priority are evaluated at request time. |
| Stacking and coupon compatibility | COMPLETED | Stacking groups and explicit coupon compatibility are enforced. |
| BOGO | CLIENT DECISION REQUIRED | Qualifying/reward products, cheapest-item behavior, odd quantities, caps, and stacking are undefined. |
| Free garlic bread/free item | CLIENT DECISION REQUIRED | Reward SKU, substitution, availability, quantity, and stacking rules are undefined. |
| Family combo | CLIENT DECISION REQUIRED | Components, quantities, substitutions, extras, fixed price/discount, and availability behavior are undefined. |
| Student discount | CLIENT DECISION REQUIRED | Verification, entitlement lifetime, value, eligibility, limits, retention, and stacking are undefined. |
| Promotion display on home page | FRONTEND / API CONTENT | Promotion CRUD/list APIs exist; visual placement is frontend scope. |

### 3.7 Payments and receipts

| Client feature | Status | Backend evidence / gap |
|---|---|---|
| Online card payment | COMPLETED, PROVIDER TEST PENDING | SumUp checkout adapter, authoritative amount/currency, idempotency, verified status, webhook handling, and receipt issuance exist. |
| Credit/debit cards | COMPLETED, PROVIDER TEST PENDING | Exposed through hosted/provider checkout; exact methods depend on the configured SumUp merchant account. |
| Apple Pay, Google Pay, digital wallets | PROVIDER CAPABILITY/POLICY PENDING | No client-controlled wallet implementation should be invented; availability depends on the selected SumUp checkout/product and merchant configuration. |
| Cash on delivery | COMPLETED | Starts `collection_pending`; assigned driver/admin collection is authoritative and race-protected. |
| Card/debit on delivery | COMPLETED | External-terminal collection is represented separately from online SumUp checkout and produces a receipt. |
| Digital receipt | COMPLETED | Unique receipt issuance exists for verified online or collected delivery payments. |
| Payment status | COMPLETED | Customer-owned status route and internal transaction/order states exist. |
| Refunds | COMPLETED, PROVIDER TEST PENDING | Partial/full balance enforcement, concurrency, provider failure handling, status updates, and report linkage exist. Real SumUp refund smoke is pending. |

### 3.8 Orders, ETA, and delivery

| Client feature | Status | Backend evidence / gap |
|---|---|---|
| Order creation and number | COMPLETED | Atomic checkout creates immutable order data and identifiers. |
| Default 30-minute ETA | COMPLETED | Restaurant schema defaults to 30 minutes and restaurant creation uses 30 when omitted. Checkout uses the configured value. |
| Received/accepted/preparing/baking/packing | COMPLETED | Explicit order status machine and history exist. |
| Driver assigned/out for delivery/arriving/delivered | COMPLETED | Delivery assignment state machine synchronizes order state, tracking history, and notifications. |
| Driver acceptance and location | COMPLETED | Assigned-driver/admin authorization and location updates exist. |
| Customer tracking and remaining minutes | COMPLETED at persistence/API layer | Owner-scoped tracking route exposes state/ETA data. |
| Realtime customer stream | COMPLETED, PROVIDER TEST PENDING | Durable AppSync event boundary exists; real subscriptions/authorizer require credentials and deployed configuration. |
| Visual progress bar/countdown | FRONTEND SCOPE | Backend provides state and timing; rendering is mobile UI work. |

### 3.9 Notifications

| Client feature | Status | Backend evidence / gap |
|---|---|---|
| Order confirmed | COMPLETED, PROVIDER TEST PENDING | Outbox/in-app/push boundary exists. |
| Preparing | COMPLETED, PROVIDER TEST PENDING | Order state events feed notification handling. |
| Out for delivery | COMPLETED, PROVIDER TEST PENDING | Delivery/order outbox behavior exists. |
| Driver arriving | COMPLETED, PROVIDER TEST PENDING | Explicit arriving event persists and dispatches. |
| Delivered | COMPLETED, PROVIDER TEST PENDING | Delivered state dispatch exists. |
| New promotions/special discounts | PARTIALLY COMPLETED | Notification and promotion infrastructure exists, but the campaign job is intentionally empty; target audience, consent, cadence, and trigger rules are undefined. |
| Coupon expiration | PARTIALLY COMPLETED | No active scheduled workflow exists. Recipient selection and notification lead time must be defined. |
| Preference rules and invalid tokens | COMPLETED | Preferences, marketing opt-out, delivery records, retries, and invalid-token retirement exist. |

### 3.10 Search, filters, favorites, and reorder

| Client feature | Status | Backend evidence / gap |
|---|---|---|
| Search by name/ingredient/category/price | COMPLETED | Database-side query filters exist. |
| Vegetarian, vegan, gluten-free, spicy | COMPLETED | Dietary flags are supported. |
| Popular, newest, lowest/highest price | COMPLETED | Deterministic sorting/filtering exists. |
| Favorite add/list/remove | COMPLETED | Customer ownership and uniqueness are enforced. |
| Reorder previous order | COMPLETED | Availability-aware atomic batch reorder exists. |
| One-tap reorder directly from favorite | COMPLETED | `POST /favorites/:id/cart` validates ownership, reconstructs the saved configuration, and sends it through current availability and authoritative cart pricing. |

### 3.11 Customer support

| Client feature | Status | Backend evidence / gap |
|---|---|---|
| Support tickets and order issues | COMPLETED | Customer-owned ticket creation/list/detail exists. |
| Messages/live chat | COMPLETED, PROVIDER TEST PENDING | Durable messages, unread/read, agent claims, outbox, and realtime authorization exist. Real AppSync smoke is pending. |
| Attachments | COMPLETED, PROVIDER TEST PENDING | Attachment/media relationships exist; real S3 behavior is pending. |
| Support agent reply/resolve/close | COMPLETED | Queue, atomic claim, reply, read, and status management exist. |
| FAQ | COMPLETED | Public list/detail and protected administration routes exist. |
| Refund request | COMPLETED, PROVIDER TEST PENDING | Refund request/approval/status flow exists; real provider execution is pending. |
| Phone and email support | FRONTEND / OPERATIONAL SCOPE | Contact details, mailboxes, and call handling are external operations; they are not an in-app backend workflow in the supplied requirements. |

### 3.12 Administration and reporting

| Client feature | Status | Backend evidence / gap |
|---|---|---|
| Menu/category/ingredient/option management | COMPLETED | Protected CRUD and pricing configuration routes exist. |
| Promotion/coupon management | COMPLETED for supported rules | Protected CRUD exists; ambiguous commercial promotion types remain controlled unsupported. |
| Order and delivery management | COMPLETED | Admin queue/status/assignment behavior exists. |
| Customer and staff management | COMPLETED | User, staff, role, permission, and privacy administration foundations exist. |
| Refund management | COMPLETED, PROVIDER TEST PENDING | Approval/provider boundary and locked financial rules exist. |
| Gross sales and recognized revenue | COMPLETED | Date/restaurant-scoped reporting exists. |
| Refunds and net revenue | COMPLETED | Refunded rows feed exact net reporting. |
| Discounts, tax, delivery fees | COMPLETED | Exact minor-unit aggregates exist. |
| Total orders and AOV | COMPLETED | Counts and average order value are returned. |
| Daily revenue | COMPLETED | Zero-filled daily recognized/refund/net series exists. |
| Popular items | COMPLETED | Recognized-order quantity ranking exists. |

### 3.13 Security and privacy

| Client feature | Status | Backend evidence / gap |
|---|---|---|
| Secure authentication | COMPLETED | Hashed passwords/tokens, rotation, account state, throttling, JWT and deny-by-default authorization exist. |
| Protected customer/order data | COMPLETED | Ownership predicates and global role/permission guards exist. |
| Encrypted provider payment processing | COMPLETED, PROVIDER TEST PENDING | Hosted/provider architecture avoids raw card storage; TLS/provider validation is external. |
| Consent history | COMPLETED | Versioned consent records exist. |
| Data export | COMPLETED | Owner-scoped safe JSON export excludes hashes/tokens/provider secrets/other users. |
| Processing restriction | COMPLETED | Explicit restriction state and fulfillment exist. |
| Deletion/anonymization | COMPLETED for current technical policy | Identity is anonymized and financial/audit records retained/redacted. |
| Legal compliance policy | CLIENT DECISION REQUIRED | Lawful basis, retention periods, SLA, rectification, and final erasure boundary require legal/product approval. This report does not claim legal compliance. |

### 3.14 User experience requirements

Simple navigation, mobile responsiveness, food presentation, progress bars, smooth animations, and store-ready mobile builds are **frontend/mobile scope**. The backend contributes pagination, indexed queries, compact API responses, server-side filters, and authoritative checkout behavior, but cannot by itself satisfy visual UX requirements.

## 4. Missing and incomplete backend work

### 4.1 Defined technical gaps

1. **Promotion/coupon notification workflow:** after the client defines audience, consent, timing, frequency, and expiry lead time, activate an idempotent scheduled/outbox workflow.
2. **Authenticated HTTP acceptance depth:** add realistic seeded customer, administrator, driver, and support HTTP journeys. Current high-risk business logic is database-tested, but the complete controller-to-database journeys are not represented by one comprehensive suite.
3. **Response contract refinement:** many legacy Swagger operations lack explicit response DTOs/examples even though routes are generated and discoverable.

### 4.2 Optional gaps

1. Google login adapter, token verification, account linking, and route.
2. Apple login adapter, token verification, account linking, and route.
3. Phone verification/SMS flow if the client confirms it is required beyond accepting a phone number at registration.

### 4.3 Client decisions required before implementation

1. BOGO qualifying/reward products, quantities, cheapest-item handling, caps, and stacking.
2. Free-item reward SKU, substitutions, availability, quantities, and stacking.
3. Family-combo composition, substitutions, extras, availability, and pricing model.
4. Student verification method, discount value, entitlement lifetime, limits, privacy retention, and stacking.
5. Loyalty earn rate, redemption value, qualifying order/payment status, expiry, refund reversal, caps, and stacking.
6. Promotion/coupon notification audience, opt-in category, cadence, and expiration lead time.
7. Privacy retention, fulfillment SLA, rectification process, and approved anonymization/erasure boundary.

### 4.4 Provider verification pending

- Gmail/SMTP delivery.
- AWS S3 upload/finalize/delete and public asset delivery.
- SumUp hosted checkout, webhook reachability, reconciliation, and refunds.
- AWS AppSync realtime publication/subscription authorization.
- Firebase push delivery and mobile token behavior.

These are not missing adapters; real credentials were intentionally not supplied or exercised.

## 5. Milestone image reconciliation

| Milestone | Client deliverable | Current backend assessment |
|---|---|---|
| Week 1 | Requirements, architecture, setup, repository | COMPLETED for backend. Architecture, NestJS modules, PostgreSQL migrations, environment validation, and documentation exist. UI direction is frontend scope. |
| Week 2 | Authentication, profile, menu structure, admin foundation, base APIs | COMPLETED, except optional Google/Apple login and the customer payment-method API gap. |
| Week 3 | Categories, customization, cart, coupons, menu/ingredient management, pricing | COMPLETED for defined rules. Ambiguous promotional deal types remain client decisions. |
| Week 4 | Checkout, Stripe, orders, dashboard, status workflow | Checkout/orders/status are COMPLETED. The image says Stripe, while the current approved implementation and environment use **SumUp**. The client must confirm that SumUp supersedes Stripe; both should not be maintained accidentally. Admin dashboard UI is frontend scope. |
| Week 5 | Notifications, history, favorites, reports, fixing/polish | Core backend is COMPLETED. Real providers are pending; promotion/coupon campaigns, direct favorite quick-reorder, explicit response DTO polish, and full HTTP acceptance depth remain. |
| Week 6 | QA, deployment, app builds/store submission, final testing/docs/handover | Backend build, automated tests, OpenAPI, route inventory, and reports exist. Deployment, mobile builds, store submissions, and production provider verification are separate tasks. |

The image estimates four to six weeks only after advance payment, domain confirmation, account access, final content, approved requirements, timely feedback, and third-party account availability. Those commercial assumptions cannot be validated from the repository.

## 6. Important scope discrepancies

1. **Stripe vs SumUp:** the milestone image names Stripe; the current backend and environment inventory implement SumUp. Obtain written confirmation that SumUp is the final provider.
2. **Optional social login:** the functional document calls Google/Apple optional. The schema anticipates them, but working integrations are not present.
3. **Saved payment methods:** the document calls them optional. Storage/service foundations exist without a customer API.
4. **Loyalty:** explicitly optional and commercially undefined; it must not be connected to checkout until rules are approved.
5. **Promotional examples are not specifications:** BOGO, family combo, free item, and student discount need executable definitions.
6. **Frontend claims:** progress bars, fast navigation, attractive imagery, responsive layout, mobile builds, and store submission cannot be marked complete from backend evidence.

## 7. Recommended completion order

1. Obtain client confirmation for SumUp versus Stripe and all decision-required promotion/loyalty/privacy rules.
2. Decide whether optional Google/Apple login and phone verification belong to the first release.
3. Define and implement promotion/coupon notification scheduling and consent behavior.
4. Add seeded authenticated HTTP journeys for customer, admin, driver, and support roles.
5. Replace implicit Swagger response contracts with explicit response DTOs for public/mobile-facing operations.
6. When credentials become available, execute isolated provider smoke tests without weakening the fake-provider regression suite.

## 8. Final assessment

### Completed feature groups

Authentication fundamentals, profile/address management, safe saved-payment-reference management, menu/catalog, all three pizza modes, server pricing, cart, defined promotions/coupons, checkout, orders, order history/reorder, SumUp architecture, cash/card-on-delivery, receipts, delivery lifecycle, ETA, persisted tracking, core notifications, search/filtering, favorites with quick reorder, support/chat foundations, FAQ, refund logic, administration, reporting, security, privacy technical workflows, migrations, worker/outbox behavior, and API documentation generation.

### Missing or incomplete feature groups

Optional Google/Apple login, optional phone verification, active promotion/coupon notification campaigns, complete authenticated HTTP role journeys, and precise response DTO documentation across legacy endpoints.

### Decision- or provider-dependent groups

BOGO, family combo, free-item and student promotion rules; loyalty economics; privacy legal policy; Stripe-versus-SumUp confirmation; real SMTP/S3/SumUp/AppSync/Firebase verification; and frontend/mobile/store work.

**Final conclusion:** the backend covers the core restaurant ordering and administration system, but the client-facing project should not be described as universally complete until the defined technical gaps are closed and the client resolves the listed optional and ambiguous requirements.
