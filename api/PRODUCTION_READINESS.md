# Production Readiness

## Architecture and processes

- NestJS HTTP API: `npm run start:prod` after `npm run build`.
- Separate durable outbox worker: `npm run start:worker`. It polls PostgreSQL, claims with `SKIP LOCKED`, retries five times with backoff, recovers stale claims and exits after the current batch on SIGTERM/SIGINT.
- PostgreSQL is the source of truth. Run migrations, never `synchronize:true`.
- Optional boundaries: SumUp, SMTP, S3, AppSync Events and Firebase. Disabled optional providers must not make API readiness fail.

## Required infrastructure

PostgreSQL with backups/PITR, HTTPS ingress, secret manager, API and worker deployments, centralized structured logs, metrics/alerts, and a migration job. Provider resources require least-privilege credentials. AppSync client subscriptions require a Lambda authorizer enforcing JWT identity and ticket membership.

## Configuration

Use `.env.example` as the inventory; inject secrets through the platform. Production startup validates database/JWT, enabled provider settings, URLs, ports, booleans and worker bounds. Never commit `.env`. Rotate leaked credentials immediately.

## Health policy

- `GET /health`: process liveness only.
- `GET /ready`: validated startup configuration plus PostgreSQL connectivity.
- Optional provider outages do not remove the API from rotation; provider delivery is retried through the outbox and alerted separately.

## Deployment sequence

1. Back up and verify restore capability.
2. Build immutable API/worker artifact.
3. Run tests and generate `openapi.json`.
4. Apply migrations as a single controlled job; verify the second run is a no-op.
5. Deploy API, verify `/health` and `/ready`.
6. Deploy one worker, inspect outbox lag/errors, then scale workers if required.
7. Run safe provider smoke tests and a customer/admin acceptance path.
8. Enable traffic gradually and monitor database pool, latency, errors, payment reconciliation and dead letters.

Rollback application code independently when schema remains forward-compatible. Never revert a production migration casually; use a reviewed forward repair migration. Pause workers before a rollback that changes event contracts.

## Provider readiness

- SumUp: configure merchant/API key/return URL; expose HTTPS webhook; verify merchant/reference/amount/currency; monitor pending reconciliation.
- SMTP: configure credentials/from identity and SPF/DKIM/DMARC; test reset, verification and order mail.
- S3: private bucket, blocked public access, encryption, lifecycle, scoped IAM, CORS, optional CloudFront for public menu assets, and malware/content scanning policy.
- AppSync Events: backend publish-only API key, private namespaces, Lambda authorization and channel membership checks.
- Firebase: service account from secret manager; configure iOS APNs/Android apps; monitor invalid tokens and transient failures.

## Observability and operations

Alert on API readiness, 5xx rate, slow queries, pool exhaustion, outbox age, failed/dead-letter counts, payment reconciliation age and refund failures. Logs must not contain request bodies, tokens, provider keys, reset links, payment payloads or customer PII. Current logs are not yet a complete correlation-ID/metrics implementation.

## Scheduled work

Promotion activation is evaluated from configured validity windows at query/checkout time, and reporting uses live aggregates, so neither requires a cron job. Coupon-expiry notifications, campaigns and loyalty expiry remain intentionally inactive because recipient, timing and loyalty-expiry rules are undefined. Define schedules, idempotency and ownership before enabling them.

## Backups and security

Test restore procedures, define RPO/RTO and retention, restrict database networking, enforce TLS, scan dependencies/images, preserve payment/audit records according to approved policy, and conduct an external security review before launch.

## Release blockers

See `CLIENT_DECISIONS_REQUIRED.md`. Real provider smoke tests, infrastructure/observability, production migration rehearsal, full authenticated HTTP journeys and the listed promotion/loyalty/privacy policies remain unresolved. The credential-independent backend is complete for defined rules, but deployment is not verified.
