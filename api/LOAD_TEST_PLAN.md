# Safe Load-Test Plan

Run only against an isolated staging database with fake mail, S3, SumUp, AppSync and Firebase adapters. Seed deterministic customers, menu/configuration and carts. Never target production payment/refund providers.

| Operation | Scenario |
|---|---|
| `GET /menu` | browse, filters and text search with cold/warm cache |
| `POST /pricing/calculate` | standard, modified and builder configurations |
| `GET /carts/me` | populated cart detail/repricing |
| `POST /carts/me/items` | unique customer carts; no shared mutable fixture |
| `POST /checkout` | unique idempotency keys plus deliberate retries |
| `GET /orders/me` | varying history depth |
| `GET /deliveries/orders/:id/tracking` | ownership-scoped reads |
| `POST /support/tickets/:id/messages` | independent conversations under route throttling |

Measure p50/p95/p99 latency, throughput, HTTP/validation/provider error rates, PostgreSQL pool wait/utilization, query count, slow queries, locks/deadlocks, outbox lag and worker retry/dead-letter rates. Establish baselines before choosing targets. Suggested release gates for ordinary reads are p95 under 300 ms and error rate below 1% at agreed launch concurrency; checkout targets must be agreed after staging/provider latency is known.

Ramp gradually, hold steady state, then run a short spike. Keep checkout datasets disposable. Verify database recovery, idempotency and no cross-user leakage after every run.
