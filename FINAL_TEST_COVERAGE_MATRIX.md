# Final Test Coverage Matrix

`Yes` means current automated evidence exists; `Partial` means a narrower boundary is covered. Provider smoke never means a mock.

| Requirement area | Unit | PostgreSQL integration | HTTP E2E | Real provider | Manual/deployment |
|---|---:|---:|---:|---:|---:|
| Authentication/security | Yes | Yes | Auth boundary only | SMTP skipped | Verification delivery/config |
| Profile/addresses/privacy | Ownership unit | Export/restriction/anonymization | Protected routes | N/A | Legal retention/SLA |
| Menu/search/filter | Pricing/query unit | Yes | No full journey | N/A | Representative production data |
| Pizza configuration/pricing | Yes | Partial | No full journey | N/A | Admin configuration matrix |
| Cart/checkout/promotions/coupons | Yes | Promotion/concurrency | No full journey | N/A | BOGO/combo/student decisions |
| Orders/history/reorder | Ownership/unit | Partial | No full journey | N/A | Operational transition review |
| SumUp/payments/refunds/receipts | Provider unit | Yes | No full journey | Skipped | Sandbox/webhook/reconciliation |
| Pay on delivery | Service boundary | Yes, including duplicate race | Protected route | N/A | Terminal/cash operations |
| Delivery/ETA/tracking | Ownership unit | Full state journey/concurrency | Protected routes | AppSync skipped | Mobile/provider acceptance |
| Notifications/push | Provider unit | Yes | No journey | Firebase skipped | Mobile token/background behavior |
| Mail | Provider unit | Outbox indirect | No journey | SMTP skipped | Deliverability/DNS |
| S3/media | Provider unit | No complete journey | No | S3 skipped | IAM/CORS/scanning/CDN |
| Support/live chat | Provider unit | Yes, including claim | No complete HTTP journey | AppSync skipped | Lambda authorizer/channels |
| Favorites/FAQ | No dedicated | Constraint only | No | N/A | API acceptance |
| Loyalty | No dedicated | No transactional suite | No | N/A | Business rules/scheduler |
| Reporting | Query validation | Exact expected-value suite | Protected route | N/A | Production-scale performance |
| RBAC/admin | Guard/ownership unit | Auth DB | Protected route only | N/A | Full role matrix |
| Migrations/schema | N/A | 21 fresh + no-op | N/A | N/A | Production migration rehearsal |
| Health/readiness | N/A | DB-backed e2e | Yes | Optional providers excluded | Probe wiring |
| Worker/outbox | Provider unit | Chat processing | No | Providers skipped | Poller/dead-letter alerts |

The delivery, reporting, privacy and pay-on-delivery persistence journeys have credible PostgreSQL coverage. HTTP E2E currently proves application startup/readiness and authentication boundaries, not full authenticated customer/admin workflows; those must not be reported as full HTTP journeys.
