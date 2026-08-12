# Customer application security review

Status: **REJECT / release blocked**  
Review date: 2026-08-12  
Reviewer pass: 1 of 2 maximum revisions

## Gate verdict

The frozen customer delivery is **not accepted**. No P0 was confirmed, but five
P1 findings remain unresolved. Acceptance requires zero unresolved P0/P1, or
explicit human risk acceptance; no such acceptance was requested or granted.

Provider activation, production testing, credential rotation, risk acceptance,
and expansion of the authorized boundary remain human gates. In particular,
recent-customer-reauthentication proof is not implemented merely because a
generated schema exists.

## Review contract and limits

- Authorized code/config target: `customer/**`,
  `packages/la_favola_generated_api/**`, and the bounded customer
  session/privacy/controller/service/DTO/test/OpenAPI changes under `api/`.
- Allowed activity: read-only repository/config inspection, bounded secret and
  dependency/static review, and safe non-destructive local tests.
- Excluded: production/external access, offensive testing, provider activation,
  credential CSV reads, unrelated admin scope, credential changes, disclosure,
  and risk acceptance. No credential CSV was opened.
- Severity model: P0 critical, P1 release-blocking high, P2 medium hardening,
  P3 low. Likelihood and impact are assessed separately below.
- Iteration limit: two independent review passes under the producer contract;
  this document records pass 1. The reviewer changed no code/config.

## Architecture, data flows, and trust boundaries

```text
Customer UI / GoRouter
  -> Riverpod CustomerSessionController
     -> access token in Dart process memory
     -> rotating refresh token in flutter_secure_storage
  -> HttpWeek2Gateway / CustomerApiClient
     -> configured API origin (HTTPS required in release)
     -> JWT-authenticated NestJS controllers
        -> ownership-scoped TypeORM repositories / PostgreSQL
        -> privacy export, anonymization, refresh-session revocation
```

Trust boundaries and assets reviewed:

1. Untrusted route/deep-link/query input entering GoRouter and provider-return
   routes.
2. Device process memory versus encrypted platform storage.
3. Mobile HTTP client versus the configured API/TLS origin.
4. JWT identity versus customer-owned sessions, privacy requests, carts,
   addresses, orders, and exported personal data.
5. Generated API contract versus the deployed Nest controller contract.
6. Retry/replay boundary spanning handset process lifetime and backend
   idempotency records.

Threat assumptions: an attacker may control route/query values and API input,
may obtain a still-valid customer access token, may cause network interruption
or app termination at retry boundaries, and may attempt cross-customer UUIDs.
The attacker is not assumed to possess production infrastructure credentials,
break TLS/Android Keystore, or control the approved build environment.

## Findings

### SEC-CUS-001 — Privacy fulfillment lacks required recent reauthentication

- Severity: **P1 / High**
- Likelihood: Medium
- Impact: High
- Threat scenario: an attacker with a stolen but still-valid access token
  creates or selects a privacy request and calls the fulfillment endpoint to
  obtain the complete account export or irreversibly anonymize the account,
  without knowing the current password or presenting a short-lived proof.
- Affected asset/boundary: personal-data export and account deletion; JWT to
  destructive privacy-operation boundary.
- Evidence: `api/src/modules/customers/privacy.controller.ts` exposes
  `POST customers/me/privacy/requests/:id/fulfill`; the handler accepts only
  `CurrentUser` and a request ID. `CustomersService.fulfillPrivacyRequest`
  directly calls `buildExport` or `anonymizeAccount`. No proof DTO, proof
  validation, action binding, expiry, or single-use check exists. The customer
  README requires a short-lived proof, while the generated
  `customerReauthenticate` route has no matching backend controller.
- Remediation: implement a server-issued, short-lived, single-use proof after
  current-password verification. Bind it to user ID, exact action, and privacy
  request; consume it atomically in fulfillment. Require stronger confirmation
  for deletion. Do not treat provider activation or human reauth proof as
  complete until the real backend path is implemented and reviewed.
- Verification: controller tests must reject absent, expired, reused,
  wrong-user, wrong-action, and wrong-request proofs; a focused integration test
  must prove valid proof consumption and atomic single use for export/deletion.
- Residual risk: access-token theft still exposes ordinary account data until
  token expiry; step-up limits destructive and bulk-export consequences.

### SEC-CUS-002 — Secure-storage failure leaves logout authenticated in memory

- Severity: **P1 / High**
- Likelihood: Low to Medium
- Impact: High on a shared/lost device
- Threat scenario: secure-storage deletion fails during logout. Remote logout
  may run, but the controller never changes to `signedOut`; GoRouter and the
  controller's access-token getter retain the authenticated session in memory.
- Affected asset/boundary: bearer access token and authenticated local session;
  secure storage to process-memory/logout boundary.
- Evidence: `customer/lib/core/session/customer_session_controller.dart`
  `signOut()` awaits `tokenStore.clear()` before assigning signed-out state and
  has no outer `finally`. Its `_refresh` path already recognizes that storage
  cleanup can fail, demonstrating this is an expected platform failure mode.
  `restore()` also performs `tokenStore.read()` outside its `try`, allowing a
  read failure to leave restoration unresolved.
- Remediation: clear all in-memory session state first or unconditionally in a
  `finally`; make remote revocation and encrypted-store deletion best effort,
  while recording a non-sensitive retry notice. Wrap storage read/write/delete
  consistently and prevent stale-token restoration loops.
- Verification: tests with stores that throw on read, write, and clear must
  prove logout always removes the bearer from memory, guard state becomes
  signed out, restoration terminates, and later requests carry no Authorization
  header.
- Residual risk: a refresh token that could not be deleted remains encrypted at
  rest until cleanup/revocation succeeds; the UI must state the safe recovery
  behavior without exposing token material.

### SEC-CUS-003 — Privacy-request list serializes internal ownership and notes

- Severity: **P1 / High**
- Likelihood: High when the endpoint is used
- Impact: Medium to High, depending on internal note content
- Threat scenario: an authenticated customer lists privacy requests and
  receives raw entity fields, including the internal `userId` and operational
  `notes`, even though the new single-request contract intentionally omits them.
- Affected asset/boundary: internal privacy-review metadata and raw customer
  UUID; persistence entity to public API response boundary.
- Evidence: `CustomersService.privacyRequests()` returns TypeORM
  `PrivacyRequest` entities directly. The entity includes `userId` and `notes`.
  By contrast, `privacyRequest()` maps a narrow DTO and the unit test explicitly
  asserts that `userId` and `notes` are absent only for the single-item path.
- Remediation: map both list and detail through the same explicit customer-view
  DTO; never serialize persistence entities. Add an array response DTO to
  OpenAPI and an allowlist serialization test.
- Verification: focused unit/integration tests must assert every list element
  contains only `id`, `requestType`, `status`, `requestedAt`, and `completedAt`,
  with no `userId`, `notes`, relations, or future entity fields.
- Residual risk: request IDs remain opaque identifiers needed for status lookup;
  keep ownership predicates and uniform not-found behavior.

### SEC-CUS-004 — Checkout idempotency does not survive process loss and is optional

- Severity: **P1 / High**
- Likelihood: Medium on mobile networks
- Impact: High (duplicate orders/charges or inconsistent cart recovery)
- Threat scenario: checkout succeeds but its response is lost, then the app is
  killed or the route is reconstructed. The widget-only idempotency key is lost,
  a new key is generated, and retry may create a second order. API callers may
  also omit the key because the backend DTO marks it optional.
- Affected asset/boundary: order/payment integrity; mobile lifecycle to backend
  replay boundary.
- Evidence: `CheckoutRoutePage` stores `_idempotencyKey` only in widget memory
  and generates it from the current microsecond timestamp. `CheckoutDto` marks
  `idempotencyKey` with `@IsOptional()`. `CheckoutService` provides sound
  actor/scope/request-hash replay behavior only when a key is supplied. The
  legacy `HttpWeek2Gateway.submitOrder` also clears and rebuilds the persisted
  cart before reaching the idempotent checkout call, so failures can leave the
  cart empty or partial.
- Remediation: require a bounded-format idempotency key server-side; persist the
  pending checkout intent/key and immutable request body until an authoritative
  result is recovered; retry the exact body. Remove destructive cart
  reconstruction from the client and submit the existing owned cart directly.
- Verification: integration tests must cover lost response, concurrent same-key
  calls, same key/different body conflict, process restart recovery, and failure
  before/after order commit, proving exactly one order and a coherent cart.
- Residual risk: 24-hour backend idempotency expiry requires a documented client
  recovery window and authoritative order-history reconciliation.

### SEC-CUS-005 — Generated security/privacy paths diverge from backend routes

- Severity: **P1 / High**
- Likelihood: Certain for the affected current calls
- Impact: High because logout/session/privacy safety controls are unavailable
- Threat scenario: the customer believes it has reauthenticated, listed or
  revoked sessions, or submitted/checked a privacy action, but the generated
  client sends requests to routes the backend does not expose. Safety-critical
  controls fail at runtime and cannot be release-verified.
- Affected asset/boundary: session revocation, recent-auth proof, export and
  deletion; generated-contract to deployed-controller trust boundary.
- Evidence: generated operations use singular paths such as
  `/api/v1/customer/security/sessions`, `/api/v1/customer/privacy/*`, and
  `/api/v1/auth/customer/reauthentications`. Backend OpenAPI/controllers use
  `/api/v1/customers/me/security/sessions` and
  `/api/v1/customers/me/privacy/requests*`, and expose no customer
  reauthentication route. `HttpWeek2Gateway` invokes the generated operations.
- Remediation: choose the backend OpenAPI as the single authoritative source,
  implement the approved reauthentication semantics, regenerate the Dart
  package, and remove obsolete route contracts. Provider flags must remain off
  until both client adapter and backend configuration are capability-tested.
- Verification: generated golden inventory plus safe local HTTP contract tests
  must prove every session/privacy operation reaches a real guarded endpoint
  and that unsupported providers present a truthful unavailable state.
- Residual risk: provider-backed OAuth and production endpoints remain manual
  gates and were not tested in this review.

## Positive controls validated

- Release API origin is mandatory and restricted to HTTPS; userinfo, query, and
  fragment are rejected. Debug alone defaults to emulator HTTP.
- Android main manifest does not enable cleartext; only the debug overlay does.
- Android release signing reads four named environment variables conditionally;
  no hard-coded keystore password, alias, or path was found in the bounded scan.
- Access tokens are designed to remain in process memory and refresh tokens use
  `flutter_secure_storage`.
- Refresh coordination uses one in-flight future and ownership queries bind
  security-session/privacy-request IDs to the authenticated user.
- Session-list DTO mapping omits token hash and user ID; path parameters are UUID
  validated for the new session/detail endpoints.
- Request paths use component encoding in the inspected repositories/gateway;
  no unsafe execution, path traversal, SSRF sink, embedded private key, or
  committed customer secret was confirmed in scope.

## Validation evidence and coverage limits

Read-only evidence included durable project documents, customer/admin
architecture, Flutter/session/router/HTTP code, platform manifests/signing,
generated contracts, bounded Nest customer/checkout contracts, OpenAPI, and
focused tests. A bounded secret-pattern scan excluded credential CSVs and found
no credential value. Existing unit tests support ownership and DTO findings,
but historical test presence is not a current pass result.

No production API, provider, real credential, emulator attack, TLS interception,
dynamic instrumentation, database integration, SAST service, or offensive test
was authorized or performed. Dependency lockfiles were inspected only as local
artifacts; no network advisory refresh was performed. Therefore supply-chain
freshness, OS keystore behavior on physical devices, certificate/public-domain
configuration, and operational logging remain residual risks.

## Ordered remediation gate

1. SEC-CUS-001 server-side reauthentication proof for privacy export/deletion.
2. SEC-CUS-002 unconditional in-memory logout and storage-failure tests.
3. SEC-CUS-003 explicit list DTO mapping with leakage regression tests.
4. SEC-CUS-004 required durable checkout idempotency and exact-body recovery.
5. SEC-CUS-005 regenerate and capability-test aligned session/privacy routes.

After producer remediation, run one independent pass-2 verification. If any P1
remains after the maximum revision, record it and request a human decision; the
reviewer cannot accept the risk.
