# Customer code review — pass 1

Date: 2026-08-12  
Scope: frozen `customer/**`, `packages/la_favola_generated_api/**`, and the bounded customer-facing API/OpenAPI/test diff described by the coordinator.  
Base: current worktree against `HEAD` (`e955432`), with customer/generated files untracked and the listed API files modified.  
Verdict: **REVISE** — five unresolved P1 findings.

## Findings

### P1 — Favorite “add to cart” always violates the backend DTO

- Locations: `customer/lib/features/modernization/data/customer_feature_repositories.dart:278-281`; `api/src/modules/favorites/dto/add-favorite-to-cart.dto.ts:3-7`; `customer/lib/features/modernization/presentation/customer_feature_pages.dart:230-250`.
- Scenario: an authenticated customer selects **Add to cart** on any favorite. Flutter sends `POST /api/v1/favorites/:id/cart` with no JSON body. The global validation pipe validates `AddFavoriteToCartDto.quantity`, whose `@IsInt()` field is required at runtime even though TypeScript initializes it to `1`; the request is rejected with 400 before the service default can apply.
- Impact: the required favorite-to-cart journey cannot succeed. The async popup handler also has no error surface, so the failure escapes the UI rather than producing a recoverable state.
- Acceptance test: a customer repository/HTTP contract test must assert the request body is exactly `{ "quantity": 1 }`; a focused Nest HTTP test must perform that request with a real authenticated customer/favorite and prove 201 plus a cart line. A widget test must cover the 400/retry state without an uncaught exception.

### P1 — Checkout places an order without showing the authoritative final total

- Locations: `customer/lib/features/modernization/presentation/customer_feature_pages.dart:1198-1232,1242-1262`; `customer/lib/features/modernization/data/customer_feature_repositories.dart:477-498,522-540`; `api/src/modules/checkout/checkout.service.ts:388-445`.
- Scenario: a customer opens `/checkout` with a delivery cart. The page displays `CartSnapshot.totalMinor`, mapped only from cart `subtotalMinor`, labels it “Total verified at checkout,” and immediately posts `/checkout`. The backend computes delivery fee, tax, promotions/coupons and the resulting `grandTotalMinor` only while creating the order. No pricing/quote request is made for the selected fulfilment/address/slot before consent.
- Impact: the charged/owed amount can exceed or differ from the amount the customer reviewed. The server-authoritative pricing requirement is not met, and retrying cannot repair missing pre-submit consent.
- Acceptance test: an integration/widget flow with a non-zero delivery fee (and one discount/tax case) must show the API-calculated `grandTotalMinor` before enabling **Place order**, then assert the checkout response matches that reviewed quote or surfaces a 409 stale-price refresh requiring renewed confirmation.

### P1 — Access-token expiry breaks all routes still using `HttpWeek2Gateway`

- Locations: `customer/lib/core/api/customer_api_client.dart:63-118`; `customer/lib/core/session/customer_session_controller.dart:104-136`; `customer/lib/week2/week2_http_gateway.dart:422-476`; `customer/lib/app/customer_app.dart:45-184,264-310`.
- Scenario: after login/restoration, wait for the access token to expire and open Orders, Profile, Addresses, Preferences, Privacy, or fulfilment loading. Those screens use the legacy `HttpWeek2Gateway`. Its `_api` maps a 401 directly to `Week2FailureKind.unauthenticated` and does not invoke the new single-flight refresh controller or retry. Only `CustomerApiClient` has refresh/retry behavior.
- Impact: the router continues to consider the session authenticated while core protected journeys fail permanently until another session transition/app restart. The claimed single-flight refresh architecture applies to only part of production traffic.
- Acceptance test: use a transport that returns 401 once for each legacy protected operation and a successful refresh/second response; fire multiple protected calls concurrently and assert exactly one refresh, all calls retry with the rotated access token, and the guarded destination remains active.

### P1 — Transient refresh failures irreversibly delete a valid rotating token

- Locations: `customer/lib/core/session/customer_session_controller.dart:78-96,110-133`; `customer/test/modernization/customer_session_controller_test.dart:30-75`.
- Scenario: startup or a 401-triggered refresh encounters an offline/timeout/5xx `Week2Failure`. `_refresh` clears secure storage and signs out for every `Week2Failure`, without distinguishing invalid/revoked/reuse-detected refresh credentials from retryable transport/dependency failures. `restore` then clears the store again.
- Impact: a temporary outage logs the customer out and destroys the only persistent credential, preventing offline-cached/authenticated recovery and forcing password/provider authentication. Current tests cover success and an unexpected error, but not retryable `Week2Failure` classification.
- Acceptance test: controller tests must prove offline, timeout, 429, and 5xx failures preserve the encrypted refresh token and expose a retryable restoration state; only invalid, expired, revoked, or reuse-detected refresh responses may clear it and transition to signed out. Multiple waiters must still complete once.

### P1 — The generated 35-operation package is self-consistent but materially drifted from the checked-in OpenAPI

- Locations: `packages/la_favola_generated_api/test/golden_test.dart:20-48`; `packages/la_favola_generated_api/test/fixtures/operation-inventory.json:1-212`; `packages/la_favola_generated_api/lib/la_favola_api.dart:982-1796`; `api/openapi.json:1981-2190`; `customer/lib/week2/week2_http_gateway.dart:878-945`.
- Scenario: the golden test compares the generated library to a hand-maintained fixture from the same obsolete 35-operation contract. For example, it asserts singular `/api/v1/customer/security/sessions` and `/api/v1/customer/privacy/...`; current OpenAPI exposes `/api/v1/customers/me/security/sessions` and `/api/v1/customers/me/privacy/requests...`. Production Preferences/Privacy still execute these generated contracts, so security sessions/privacy requests reach absent routes. The package also retains old menu/order/quote paths and omits the broader modernization surface (cart, builder/pricing/checkout, favorites, rewards, notifications, support, FAQ, saved payment methods, receipt/reorder).
- Impact: passing generated tests do not demonstrate OpenAPI compatibility; customer privacy/security journeys fail at runtime, and “35 operations” is contract drift rather than acceptable generated coverage.
- Acceptance test: generate/derive the operation inventory from the checked-in authoritative `api/openapi.json`; assert every production customer operation has identical method/path/request/response schema and every generated operation resolves to an OpenAPI operation. Add HTTP contract tests for security-session list/revoke and reauthenticated privacy export/deletion/status using the exact client operations.

## Open questions

- Which single adapter is approved for all customer traffic: the generated client or the centralized raw HTTP client? Keeping three request paths (`CustomerApiClient`, generated contracts, and `_api`) makes refresh/error/contract behavior divergent.
- Is checkout required to use a pre-order quote identifier/version, or should `/checkout` gain an explicit preview/revalidation contract? That is an approved contract decision, not a UI-only fix.

## Residual risks

- Cart/favorite/payment/order mutation buttons use widget-local async callbacks without shared in-flight serialization or consistent caught error states; this pass did not expand each into a separate finding after the confirmed blockers above.
- The supplied green counts were not independently re-run in this shortened pass. Existing modernization tests mostly record mocked calls/self-consistency and do not reproduce the failures above.
- Android runtime, offline cache/reconnect, release endpoint, privacy/legal handling, provider readiness, accessibility, and visual behavior remain separate quality gates.

## Verdict

**REVISE.** Zero-P0/P1 acceptance is not met. Fix and revalidate all five P1 findings before pass 2; no risk is accepted by this review.
