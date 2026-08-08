# P1 Core Ordering Final Completion Report

## 1. Remaining gaps closed

Automatic promotions, deterministic stacking, promotion-limit locking, separated discount accounting, request-bound checkout idempotency, transactionally atomic reorder, PostgreSQL menu queries, totals verification, forward indexes, and P1 response contracts were implemented.

## 2. Promotion engine

The engine queries active automatic promotions by restaurant and time window in explicit priority-descending/UUID-ascending order. It validates day, minimum order, menu item/category eligibility, exclusions, total usage, and per-customer usage. Percentage, fixed-amount, and free-delivery types have safe normalized semantics. The schema does not define sufficient normalized behavior for bogo, free-item, bundle, student, or custom; these are reported as `UNSUPPORTED_OR_INCOMPLETE_CONFIGURATION` rather than guessed.

## 3. Stacking policy

Only one promotion wins per `stacking_group`; highest priority wins and UUID is the stable tie-breaker. Separate groups stack unless either promotion lists the other group in `conditions.incompatibleStackingGroups`. A coupon only combines with a promotion when `conditions.couponCompatible` is explicitly `true`. Free delivery only discounts delivery.

## 4. Coupon/promotion interaction

Coupon and promotion discounts are separately calculated and persisted as `couponDiscountMinor` and `promotionDiscountMinor`; loyalty remains separate. Delivery discounts are capped at the delivery fee. Preview evaluation creates no redemption. Checkout writes coupon and promotion redemptions only inside the successful order transaction.

## 5. Concurrency protections

Checkout locks the cart, coupon, automatic promotion rows, and idempotency row. Counts are read after locks, and redemptions are written in the same transaction. Forward unique indexes prevent duplicate coupon/promotion redemption for the same order. Idempotency uses insert-on-conflict-do-nothing and a locked request-hash comparison, rejecting materially different requests with `409`.

## 6. Reorder atomicity

Reorder locks all historical menu items, sizes, choices, ingredients, and item/group mappings; revalidates current pricing while those locks are held; and writes the entire reconstructed cart in one transaction. Any invalid selection or concurrent menu change rolls back every new cart row and returns structured `422` data.

## 7. Query/performance findings

Public menu uses one joined paginated query. Checkout batches cart options and menu items. Promotion targets and redemption counts are batched. Order detail batches items/options. Reorder still performs complex pricing validation per configured line, but locks and cart writes are batched/transactional; this is intentional because each configuration has independent rules.

## 8. Index migration

Migration `1700000000017-StrengthenP1OrderingIntegrity` adds separated order discount columns, redemption uniqueness, and indexes matching public catalog, size-price, customer-order, and promotion-target queries. The original 16 migrations were not edited.

## 9. Swagger changes

Checkout now documents its complete total/discount/applied-promotion response and `409` idempotency conflict. Pricing documents its authoritative minor-unit breakdown. Existing menu query DTO decorators document the filters and pagination inputs.

## 10. Tests added

- Eight pure order-total cases, including combined discounts, free delivery, quantity/customization totals, and non-negative clamping.
- Seven real-PostgreSQL P1 tests covering pagination/counts, all dietary/search/category/ingredient/price filters, deterministic sorts, promotion priority/stacking/coupon compatibility, unsupported configuration, usage limits, concurrent final use, rollback, and duplicate redemption.
- Migration validation updated from 16 to 17 forward migrations plus no-op rerun.

The database suite directly proves promotion locking behavior. Full parallel HTTP checkout/reorder orchestration remains valuable regression expansion; it is not represented as already tested here.

## 11. Principal files changed

- `src/modules/promotions/promotions.service.ts`
- `src/modules/checkout/checkout.service.ts`
- `src/modules/carts/carts.service.ts`
- `src/modules/orders/orders.service.ts`
- `src/modules/pricing/order-totals.service.ts`
- `src/database/migrations/1700000000017-StrengthenP1OrderingIntegrity.ts`
- `test/integration/p1-ordering.database.spec.ts`
- `test/unit/order-totals.spec.ts`

## 12. Remaining external-integration work

SumUp, SMTP/Nodemailer, AWS S3, push delivery, live chat/realtime infrastructure, and other external providers were not started.
