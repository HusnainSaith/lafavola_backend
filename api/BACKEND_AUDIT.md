# La Favola Backend Audit

Audit date: 2026-08-08

## Executive summary

The repository is a generated, compileable application skeleton, not a production-ready backend. It contains 16 schema migrations, 70 entities, 67 DTOs, 34 controllers, 44 services, and 27 repositories. `npm run build` succeeds, but there are no unit or integration tests and `npm test -- --runInBand` fails with "No tests found". Lint also fails across the generated source.

Large-scale feature work should pause until the P0 identity, schema-loading, authorization, and error-pipeline issues below are resolved and covered by tests.

## Baseline validation

| Check | Result | Notes |
|---|---|---|
| TypeScript/Nest build | Pass | `npm run build` |
| Unit tests | Fail | Zero `*.spec.ts` files |
| Lint | Fail | Widespread CRLF/Prettier errors and unused generated Swagger imports |
| Migration execution | Not verified | Requires a configured PostgreSQL instance; migration discovery is currently suspect |
| End-to-end tests | Not verified | No meaningful test suite found |

The worktree contained pre-existing deleted backup artifacts and untracked requirement/image files. They were not modified.

## P0 findings

### 1. Authentication responses expose secrets

`AuthService` uses object spread without removing `password`, so registration, login, and current-user responses can expose the selected password hash. The declared `Omit<User, 'password'>` type does not remove a runtime property.

Required fix: use an explicit response DTO/serializer and ensure the password column is `select: false`; test every authentication and user response for absence of password and token-storage fields.

### 2. Password reset leaks bearer credentials and enables account enumeration

The password-reset endpoint logs the reset JWT, returns it in the API response, and returns `404` for an unknown email. This leaks credentials and reveals whether an account exists.

Required fix: store a one-time hashed verification token, send the raw token via the mail boundary, always return the same accepted response, impose attempt/expiry limits, consume tokens atomically, and revoke sessions after successful reset.

### 3. Refresh tokens are stored in plaintext and are not rotated

Refresh JWTs are persisted and queried as raw bearer tokens. Refreshing creates only a new access token and leaves the same refresh token reusable. The authoritative migration already provides token hashes/revocation fields, so the service/entity mapping must be reconciled with it.

Required fix: opaque high-entropy refresh tokens or JWTs with unique IDs, hashed at rest, rotation in a transaction, reuse detection, session-family revocation, and logout scoped to the authenticated owner.

### 4. Account state and role authorization are not enforced consistently

Login does not reject pending, suspended, disabled, or deleted users. Global authentication/RBAC guards are commented out, and a controller scan shows inconsistent route protection. Registration accepts `roleId`, enabling a caller to request a privileged role if downstream validation permits it.

Required fix: public customer registration must assign the customer role server-side; enforce account state in authentication; apply deny-by-default authentication with explicit public metadata; enforce permissions and ownership on all customer/admin routes.

### 5. Migration discovery path does not match the repository layout

`database.config.ts` points to `../../migrations/*`, while migrations live in `src/database/migrations`. The runtime path must be corrected and aligned with the CLI data source for both TypeScript and compiled JavaScript. `synchronize` is correctly disabled.

Required fix: one tested migration glob strategy, followed by migration execution against an empty PostgreSQL database and a second no-op execution.

### 6. Two competing global exception pipelines are installed

`GlobalExceptionFilter` is registered through `APP_FILTER`, while `main.ts` also installs `HttpExceptionFilter`. Filter order can bypass the intended database-error mapping and produce inconsistent response contracts.

Required fix: retain one production exception filter, map PostgreSQL constraint codes rather than message substrings, hide internal details, and add tests for validation, uniqueness, FK, and unexpected database failures.

## P1 findings

- Payment schema and generated code are Stripe-oriented, but the authoritative requirement is SumUp. Existing applied migrations must not be edited; add a forward migration and a provider abstraction after verifying current official SumUp APIs and webhook security.
- External boundaries are placeholders: S3 presigning, Nodemailer/Gmail SMTP, payment provider calls, push delivery, and managed live-support transport are not production implementations.
- Pricing uses minor-unit columns in migrations, which is correct, but cart and checkout require shared authoritative recalculation tests, compatibility checks, and transaction/concurrency tests.
- Checkout, coupon redemption, payment webhooks, refunds, loyalty changes, and outbox processing require explicit atomic/idempotent tests. Schema constraints alone are insufficient.
- Swagger decoration is mechanically generated and imports many unused decorators. A successful Swagger build does not prove correct request/response schemas or route security.
- Rate limiting is duplicated (`express-rate-limit` and Nest throttling) with unrelated limits. Consolidate policy and define stricter authentication/payment buckets.
- CORS contains hard-coded unrelated `labverse.org` origins. Move allowlists entirely to validated environment configuration.
- Startup uses raw `process.env` in several places without schema validation. Fail fast on missing production secrets and invalid ports/booleans.
- Sensitive identifiers (including email addresses) are logged. Adopt structured redaction and never log tokens, password reset links, payment payloads, or customer PII.
- No tests exist despite high-risk pricing, checkout, RBAC, payment, and webhook behavior.

## P2 findings

- Normalize line endings/Prettier configuration and remove unused generated imports without mixing that mechanical change with behavioral fixes.
- Replace `any` response types with explicit DTOs and make the response interceptor contract visible in OpenAPI.
- Remove outdated generation notes referring to Stripe after provider decisions and migrations are complete.
- Add operational health/readiness checks, structured request correlation, and outbox-worker observability.

## Migration/domain assessment

The 16 migrations form a strong intended schema baseline: identity/RBAC, profiles and addresses, restaurant/media, catalog and pizza builder, cart, promotions/coupons, orders, payments/refunds, delivery tracking, notifications, favorites/loyalty, support/FAQ, audit/idempotency/outbox, and reporting. Monetary values are predominantly integer minor units with EUR constraints, and important uniqueness/index/check constraints are present.

The main risk is not missing table breadth; it is whether the 70 generated entities and services exactly implement those constraints and whether runtime migration discovery works. This must be proven by initializing TypeORM metadata and running migrations against PostgreSQL, then testing repository operations for every aggregate.

## Implementation plan

1. P0 foundation: correct migration discovery, consolidate exception handling, validate environment configuration, and establish a PostgreSQL integration-test harness.
2. P0 identity/security: safe response DTOs, customer-only registration, account-state checks, hashed rotating refresh sessions, one-time password verification/reset, and deny-by-default route authorization.
3. P1 core ordering: entity/schema reconciliation for catalog, options, pizza builder, cart, pricing, promotions, checkout, orders, and idempotency; add unit and concurrency integration tests.
4. P1 integrations: implement provider abstractions and verified adapters for SumUp, S3, SMTP/Nodemailer, notifications, and live support.
5. P1 administration/reporting: permission matrix, database-side filtering/pagination, aggregate reports, and ownership tests.
6. P2 quality: OpenAPI contract cleanup, formatting/lint cleanup, end-to-end journeys, deployment/readiness documentation, and operational telemetry.

## Definition of done

Completion requires passing build, lint, unit tests, PostgreSQL migration tests, integration tests, and end-to-end tests; verified OpenAPI generation; no exposed secrets; provider webhooks verified and idempotent; and documented environment/deployment requirements. The current repository does not yet meet this definition.
