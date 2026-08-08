# P1 Core Ordering Gap Matrix

| Requirement | Current implementation | Status | Problem | Required change |
|---|---|---|---|---|
| Public active menu | Active flag checked | PARTIAL | Availability windows, restaurant state, sizes/ingredients, pagination and filters missing | Database query DTO and joined paginated query |
| Standard pizza | Size ownership and active flag checked | PARTIAL | Restaurant/activity windows not consistently checked | Central selection validator |
| Modified pizza | Active choices and incompatibility check | INCORRECT | Choice groups need not apply to item; min/max/required/removal rules ignored | Validate item-group mappings and grouped selections |
| Build-your-own | Loads rule and delegates pricing | INCORRECT | Required group identity, topping limits and free toppings ignored | Rule-aware validator using configured group IDs |
| Authoritative pricing | Server-side integer arithmetic | PARTIAL | Formula duplicated at checkout; group validation absent | One reusable pricing service for preview/cart/checkout/reorder |
| Cart | Ownership and server snapshots present | PARTIAL | Retrieval trusts stored price and clear/coupon/reprice missing | Reprice through authoritative service and expose totals |
| Promotions | CRUD/schema present | MISSING | No automatic evaluation | Deterministic evaluator constrained to schema |
| Coupons | Window and basic discount at checkout | PARTIAL | Usage/customer limits and locking absent; duplicated formula | Coupon evaluator and locked redemption checks |
| Checkout | Transaction and cart lock present | INCORRECT | Prices copied from cart; idempotency unused; current availability not revalidated | Transactional repricing and idempotency record |
| Order snapshots | Item/option/address snapshots present | PARTIAL | Pricing metadata incomplete | Persist complete breakdown and configurations |
| Status workflow | Explicit transition map/history | PARTIAL | Update reads before transaction lock; history/detail relations incomplete | Lock and test state machine |
| Order history | Customer ownership and simple pagination defaults | PARTIAL | Controller pagination and item/customization relations missing | Query DTO and joined detail/history |
| Reorder | No endpoint/service | MISSING | Historical configuration cannot be rebuilt | Reconstruct current cart and fail explicitly on unavailable selections |
| Restaurant availability | Active restaurant checked at checkout | PARTIAL | Business hours ignored | Availability service/query at final checkout |
| Concurrency | Cart lock during checkout | PARTIAL | Coupon limits/idempotency/order transition races remain | Locks, uniqueness/idempotency, database tests |
