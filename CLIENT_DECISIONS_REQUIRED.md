# Client Decisions Required

These are product decisions the backend cannot safely infer. This is technical analysis, not legal advice.

## BOGO

Client questions:

- Which menu items qualify and which item becomes free?
- Is the cheapest eligible item free?
- Is it always buy-one-get-one or are quantities configurable?
- Can it stack with coupons or other promotions?
- What total and per-customer usage limits apply?

- Requirement: Buy One Get One Free.
- Missing decisions: qualifying and reward items/sizes, whether the cheapest eligible item is free, odd quantities, per-order limits, stacking and schedule.
- Options: same-item pair; configured qualifying/reward groups; cheapest eligible reward.
- Recommendation: configured qualifying/reward groups with cheapest eligible reward, one reward per qualifying pair, explicit stacking flag.
- Impact: promotion configuration schema/API and pricing/redemption tests.

## Family combo

Client questions:

- Which items and required quantities belong to each combo?
- Is pricing fixed or a percentage/fixed discount?
- Can included pizzas be modified, and how are extras priced?
- Can a combo stack with coupons or promotions?

- Requirement: family combo deal.
- Missing decisions: included item groups, required quantities, allowed substitutions, fixed bundle price versus discount, and partial availability behavior.
- Options: fixed SKU; configurable bundle components; automatic basket discount.
- Recommendation: a fixed menu bundle SKU for the initial release because pricing and availability remain explicit.
- Impact: catalog representation, configuration validation and snapshots.

## Student discount

Client questions:

- How is student status verified and for how long?
- Is the discount percentage-based or fixed?
- Which products are eligible?
- What per-order, per-customer and time-based limits apply?
- When does eligibility expire, and can it stack?

- Requirement: student discount.
- Missing decisions: verification provider/manual evidence, eligibility lifetime, percentage/fixed value, limits, stacking and personal-data retention.
- Options: staff-approved entitlement; third-party verification; one-time codes.
- Recommendation: staff-approved dated entitlement with minimal stored evidence and annual expiry, subject to privacy review.
- Impact: entitlement schema, staff workflow, audit and privacy policy.

## Loyalty

- Requirement: loyalty support exists but earning/redemption rules are underspecified.
- Missing decisions: earn rate, value per point, eligible spend/status, expiry, refund reversal, caps and stacking.
- Recommendation: decide these before connecting loyalty to checkout; current standalone balance mutation must not be treated as a completed commercial program.
- Impact: transactional checkout/refund integration and expiry scheduler.

## Delivery workflow (technical default implemented)

- Implemented default: explicit assigned-driver acceptance and manual arriving action, with explicit administrator override.
- Remaining decisions: driver eligibility, acceptance/rejection timeout, reassignment policy, geofence automation, ETA provider and proof of delivery.
- Recommendation: retain the manual default until mobile/background-location policy is approved.
- Impact: status machine, APIs, notifications and mobile behavior.

## Privacy and retention

- Requirement: operation in Italy/EU.
- Missing decisions: lawful bases, consent categories/version ownership, export format/SLA, erasure versus financial-record retention, account anonymization and retention periods.
- Implemented technical default: ownership-scoped JSON export, processing restriction and account anonymization while retaining/redacting financial and audit records.
- Recommendation: obtain product/legal approval for retention periods, SLA, rectification and the exact erasure boundary before production use.
- Impact: fulfillment worker/admin flow, retention jobs, audit and deletion/anonymization rules.

## Branch and pickup scope

- Requirement ambiguity: schema supports multiple restaurants and order types include pickup, but operational ownership and branch selection are not fully specified.
- Recommendation: confirm single versus multi-branch launch and whether pickup is in release scope.
- Impact: admin scoping, catalog selection, delivery bypass and reporting boundaries.
