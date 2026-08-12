# Customer feature coverage audit

Status: baseline-before-modernization audit — 2026-08-12

## Scope and evidence boundary

This is a static implementation audit of
`docs/customer/CUSTOMER_APP_MODERNIZATION_PLAN.md` against the production
Flutter entrypoint, the customer HTTP gateway, the generated Dart API package,
the Nest controllers, `api/openapi.json`, and existing tests. No runtime or
build result is claimed. `PROJECT.md`, `PROJECT_STATE.yaml`, `TASKS.md`,
`DECISIONS.md`, `RISKS.md`, and a repository `AGENTS.md` were absent at the
repository root when inspected. The modernization plan and checked-in
code/tests are therefore the baseline; this report does not approve product,
restaurant, fiscal, legal, data-classification, budget, timeline, or provider
policy.

Status meanings:

- **Complete**: the plan row has a production Flutter route, API-backed state
  owner, generated-client coverage, required happy/non-happy states, and tests.
- **Partial**: some production code exists, but one or more acceptance elements
  are absent or contract-drifted.
- **Missing**: no production Flutter surface/state owner exists.
- **Blocked**: the Flutter journey depends on an API operation not exposed by
  the current backend OpenAPI, or on an unresolved human policy/provider gate.

No journey is complete under that definition.

## Coverage matrix

| ID / priority | Modernization journey and acceptance target | Production Flutter route and surface | Repository/controller/state owner | Backend API evidence | Generated Dart client evidence | Happy/non-happy, localization, accessibility, motion, tests | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CUS-J01 / P0 | **Public browse/search:** real available menu, detail, category/search/filter without sign-in | `/menu` -> `CustomerMenuScreen`; `/menu/item` -> `CustomerMenuDetailScreen` in `customer/lib/week2/week2_app.dart` | Widget-local `_CustomerMenuScreenState` and `_CustomerMenuDetailScreenState`; `HttpWeek2Gateway.getMenu/getMenuItem` in `customer/lib/week2/week2_http_gateway.dart` | `GET /api/v1/menu`, `/menu/search`, `/menu/{id}` in `api/src/modules/menu/menu.controller.ts`; categories are actually `GET /api/v1/categories` | Only `publicGetMenuCategories` (`/menu/categories`) and `publicGetMenuItem` (`/menu/items/{id}`) in `packages/la_favola_generated_api/test/fixtures/operation-inventory.json`; these paths contradict current backend and production gateway | Initial loading, retry failure, empty, client-side no-results, refresh, detail not-found exist in `customer/lib/features/menu/customer_menu_experience.dart`; Italian/English strings, semantics and reduced-motion switching exist. Widget evidence: `customer/test/features/menu/customer_menu_experience_test.dart`, `home_menu_screen_test.dart`. No API-backed `/menu/search`, availability filter, offline cache, forbidden/rate-limit-specific, or deep-link test. | **Partial** |
| CUS-J02 / P0 | **Builder:** valid choices only, min/max/required/unavailable/incompatibility/removal feedback and authoritative total | Builder opens inside `/menu/item` through `CustomerMenuDetailScreen` and `_LiveCheckoutSheet`; an older `PizzaBuilderScreen` is prototype-only | Widget-local `_LiveCheckoutSheetState`; `HttpWeek2Gateway.getMenuItem/createQuote`; static prototype builder is not production state | `GET /api/v1/pizza-builder/{menuItemId}`, `POST /pizza-builder/build`, `POST /pricing/calculate` in pizza-builder/pricing controllers | No builder or pricing operation in the generated inventory | Production sheet renders groups, required/min/max and unavailable choices and requests a quote, but does not call `POST /pizza-builder/build`; no demonstrated incompatibility/removal recovery or stale builder-version path. Localized labels and semantics exist; tests touch checkout/builder entry in `customer/test/week2/week2_auth_acceptance_test.dart`; prototype-only builder tests do not prove production behavior. | **Partial** |
| CUS-J03 / P0 | **Cart:** multi-item add/edit/remove, survive route changes, conflict recovery | No dedicated cart route. `_LiveCheckoutSheet` is reached from one item detail and owns one item/quantity/choices | `_LiveCheckoutSheetState`; gateway `_pendingCheckouts`, `_pendingIdempotencyKeys`, `_pendingCheckout` maps in `week2_http_gateway.dart` | Full `/api/v1/cart`, `/cart/items`, `/cart/items/{id}` CRUD and `/pricing/calculate` exist | No cart or pricing operations | A quantity can be edited and quote retried in the sheet. There is no global cart repository/controller, cross-route persistence, cart screen, multi-item edit/remove flow, empty cart, offline cart, or 409 stale-version recovery surface. Existing HTTP tests cover some raw requests but not the required durable cart journey. | **Partial** |
| CUS-J04 / P0 | **Fulfilment:** delivery/pickup, owned address, restaurant-local ASAP/slot rules | Fulfilment controls live inside `_LiveCheckoutSheet`; addresses have `/profile/addresses` | `_LiveCheckoutSheetState`; `HttpWeek2Gateway.getFulfillmentAvailability`; `AddressesScreen` | `GET /api/v1/restaurant` and `/restaurant/availability` in `public-restaurants.controller.ts` | No restaurant/availability operations | Delivery/pickup, saved-address requirement, date/slot/ASAP, and localized failure notices are present. README documents Europe/Rome/server authority. No independent cached/offline state, dependency-specific screen, slot-expiry conflict recovery, or complete test across address ownership and closing boundary is evidenced in Flutter. | **Partial** |
| CUS-J05 / P0 | **Checkout:** authoritative review and idempotent placement, optional online payment | Checkout is the same `_LiveCheckoutSheet`; no addressable checkout route | `_LiveCheckoutSheetState`; `HttpWeek2Gateway.createQuote/applyPromotion/submitOrder` | `POST /api/v1/pricing/calculate`, `/checkout`, optional `/payments/checkouts` exist | Generated inventory exposes `/quotes*` and generic `POST /orders`; it has no current backend checkout/payment operations | Totals, coupon, payment choice, disabled in-flight submit, gateway idempotency key reuse and success navigation to tracking exist. The gateway adapts through cart/pricing/checkout rather than generated contracts. No restored retry after process loss, payment-status recovery, explicit 409 quote-expiry UI, or dedicated route/deep link. Tests cover transport/request shapes but not a real checkout integration. | **Partial** |
| CUS-J06 / P0 | **Order lifecycle:** confirmation, server-clock ETA, progress, live/reconnect recovery | Orders is tab index 1 of `/home`; tracking is an anonymous `MaterialPageRoute` pushed by `CustomerOrdersScreen` | `_CustomerOrdersScreenState`, `_CustomerOrderTrackingScreenState`; gateway `getOrders/getOrder/watchOrderEvents` | `GET /api/v1/orders/me`, `/orders/me/{id}`; delivery tracking also exists under `/deliveries/orders/{orderId}/tracking` | Generated inventory uses generic `GET /orders` and `/orders/{id}`, contradicting backend production routes | Loading/empty/retry, polling, realtime reconnect, timeline, server-time countdown and semantics exist in `customer_menu_experience.dart`. Route is not named/deep-linkable, no persisted active-order state, offline-cached order, reconnect integration test, or 300ms/reduced-motion status transition proof. | **Partial** |
| CUS-J07 / P0 | **After-order:** eligible cancel, reorder, readable non-fiscal receipt | Cancel and receipt are reachable inside tracking; receipt uses anonymous route. No reorder action/surface | `_CustomerOrderTrackingScreenState`, `_CustomerOrderReceiptScreenState`; gateway `requestOrderCancellation/getOrderReceipt` | `POST /orders/me/{id}/cancel`, `/reorder`, `GET /receipt` all exist | Generated inventory includes only a cancellation operation on a different path; no reorder or receipt operations | Destructive cancel confirmation/reason, conflict-aware gateway model, receipt loading/retry and non-fiscal notice exist; localized receipt/cancel strings exist. Reorder is entirely absent. Receipt/cancel routes are not deep-linkable. Tests exercise receipt/cancel gateway behavior, not reorder or fiscal-misrepresentation end to end. | **Partial** |
| CUS-J08 / P1 | **Favorites:** save configurations, remove and move to cart | No production route or surface; a prototype menu card has a semantics label only | No repository/controller/state owner | `GET/POST /api/v1/favorites`, `DELETE /favorites/{id}`, `POST /favorites/{id}/cart` exist | No favorites operations | No happy, empty, conflict, authentication, localization, accessibility, motion, or production test coverage. Prototype `home_menu_screen_test.dart` is not API-backed evidence. | **Missing** |
| CUS-J09 / P1 | **Rewards:** balance, history, eligible redemption | No Rewards primary destination or surface | No repository/controller/state owner | `/api/v1/loyalty/balance`, `/history`, `/redeem` exist | No loyalty operations | No eligibility/ineligible/expiry/insufficient-balance states, localization, semantics, motion, or tests in customer Flutter. Reward/campaign policy must remain server-authoritative. | **Missing** |
| CUS-J10 / P1 | **Notifications:** inbox, detail, mark read, unread count, preferences/devices | No global notifications destination or surface | No repository/controller/state owner | Full `/api/v1/notifications*` controller exists | No notification operations | No unread global state, device registration, empty/offline/permission-denied state, localized semantics, or customer tests. FCM device-token/provider readiness remains an external gate. | **Missing** |
| CUS-J11 / P1 | **Support:** create/read tickets and exchange messages | No Account help/support destination or surface | No repository/controller/state owner | Customer ticket/message/read/realtime-authorization routes exist under `/api/v1/support/tickets*` | No support operations | No ticket list/detail/compose, attachment, realtime recovery, offline, forbidden, localization, accessibility, motion, or tests in customer Flutter. | **Missing** |
| CUS-J12 / P1 | **Help:** searchable public FAQ | No public or Account FAQ route/surface | No repository/controller/state owner | Public `GET /api/v1/faq` and `/faq/{id}` exist | No FAQ operations | No loading/empty/search/offline/localization/accessibility/test coverage. | **Missing** |
| CUS-J13 / P0 | **Account:** profile, addresses, preferences and security sessions | `/home` tabs expose profile/preferences/privacy; `/profile/addresses` is named but protected. No single Account hierarchy route | `_ProfileScreenState`, `_AddressesScreenState`, `_PreferencesSecurityScreenState`; `HttpWeek2Gateway` account methods | Profile/preferences/address routes exist under `/customers/me/*`. No current OpenAPI/controller route was found for `/customer/security/sessions` or session revocation | Generated inventory contains account and security-session operations, but its `/customer/*` paths contradict the current backend `/customers/me/*` and the session routes are not in `api/openapi.json` | CRUD loading/empty/validation/conflict/destructive confirmation and localized screens exist; widget/gateway/transport tests exist. Security-session runtime calls are backend-blocked. No notification/payment/help grouping, repository/application separation, Riverpod ownership, or destination restoration. | **Blocked / partial** |
| CUS-J14 / P0 | **Privacy:** reauthenticate, export/deletion request and status | Privacy is tab index 4 under `/home`; no named request-status route | `_PrivacyScreenState`; gateway `reauthenticate/requestPrivacyExport/requestPrivacyDeletion/getPrivacyRequest` | Backend exposes `/customers/me/privacy/requests` and consent routes, but not generated-style `/auth/customer/reauthentications`, `/customer/privacy/exports`, `/deletions`, or `/requests/{id}` in current `api/openapi.json` | Generated inventory contains reauthentication/export/deletion/request-state operations on the latter paths | Password reauthentication UI, destructive deletion wording and request-state models exist, with widget/gateway/transport tests. Current runtime paths are contract-blocked; no backend-compatible adapter, request list/status restoration, legal retention acceptance, or complete accessible error-state proof. Legal/compliance meaning and data handling require human approval. | **Blocked** |
| CUS-J15 / P1 | **Payment methods:** list/default/remove configured methods | No Account payment-method route or surface; checkout only offers enum choices | No repository/controller/state owner | `GET /api/v1/payments/methods`, `PATCH /methods/{id}/default`, `DELETE /methods/{id}` exist | No saved-payment-method operations | No empty/default/remove confirmation/provider-unavailable states, localization, accessibility, or tests. Display/storage and enabled-provider policy remain human/provider gates. | **Missing** |

## Global acceptance-condition coverage

| ID / priority | Acceptance condition | Evidence and gap | Status |
| --- | --- | --- | --- |
| CUS-G01 / P0 | Every journey has a production route and API-backed repository/controller | Only splash, auth, public menu, home, item and addresses are named in `Week2Routes`; tracking/receipt use anonymous routes, six journeys have no UI, and all state is widget-local/gateway-local rather than feature repositories/application controllers. | **Missing** |
| CUS-G02 / P0 | GoRouter guards restore the intended destination after authentication | `customer/pubspec.yaml` has no `go_router`; `MaterialApp.onGenerateRoute` substitutes sign-in but does not retain/restore the requested route. Successful sign-in always resets to `/home`. Only `/home` and `/profile/addresses` are guarded. | **Missing** |
| CUS-G03 / P0 | Single-flight refresh; encrypted refresh token at rest; access token only in memory; session restoration | `customer/pubspec.yaml` has no Riverpod or secure-storage dependency. `_Week2AppState` keeps the whole `CustomerSession`, including refresh token, only in memory; no startup restoration exists. `_execute` can refresh on 401, but no shared in-flight refresh future/mutex was found. | **Missing** |
| CUS-G04 / P0 | Riverpod owns session, locale, connectivity, cart, unread count and feature state | No Riverpod dependency/import. Session/locale live in `_Week2AppState`; menu, checkout, orders and account use individual `State` objects; cart/unread/connectivity global owners do not exist. | **Missing** |
| CUS-G05 / P0 | Every data surface covers the complete state contract | Shared `Week2StatePanel/Loading/Empty` and typed `Week2FailureKind` cover many server failures. No reusable offline-cached/offline-unavailable state, connectivity owner, global stale-version recovery, rate-limit retry timing, or uniform coverage evidence exists; missing journeys cover no states. | **Partial** |
| CUS-G06 / P1 | Italian and English cover every release route and semantic label | `AppLocalizations.supportedLocales` and `app_it*.arb`/`app_en.arb` exist; the active Week2 app installs delegates. Static inspection still finds hard-coded user-facing strings in legacy/prototype areas, and missing journeys necessarily lack strings. No release-route localization inventory test exists. | **Partial** |
| CUS-G07 / P0 | 320px/tablet, 200% text, keyboard/focus and screen-reader semantics | `Week2LayoutMode`, `FocusTraversalGroup`, semantic wrappers and `week2_responsive_accessibility_test.dart` provide partial evidence. The tests cover selected Week2 flows, not every plan journey/state; missing screens have no evidence. Prototype reflow tests do not establish production-route coverage. | **Partial** |
| CUS-G08 / P1 | Normal/reduced motion follows the specified durations and preserves focus/content | Menu uses `MediaQuery.disableAnimationsOf`; `week2_theme.dart` defines no-motion page transitions. Tracking and splash have animation logic. There is no centralized semantic motion token set matching 160/180/220/300ms, no comprehensive reduced-motion test, and no evidence for missing journeys. | **Partial** |
| CUS-G09 / P0 | No raw UUID/internal enum as primary content; receipt is not called a fiscal invoice | Menu/order models retain internal IDs but primary production UI generally renders names/references. Receipt UI uses the localized non-fiscal notice and backend receipt model has `fiscalDocument`. No route-wide automated raw-ID audit exists; support-reference expansion is not implemented. | **Partial** |
| CUS-G10 / P0 | Format/analyze/unit/widget/integration, debug/release builds and Android emulator smoke pass before release claims | Test files exist, including customer widget/gateway/http/responsive tests and API customer order/integration tests. This static audit did not execute them. No checked-in evidence in scope proves the full command set, release build, or emulator smoke for this baseline. | **Unverified** |

## API and generated-client contradictions

These are implementation blockers, not naming-only documentation differences:

1. The generated package describes 35 customer/public operations, while the
   backend OpenAPI exposes the broader legacy customer API. It omits builder,
   cart, fulfilment, checkout, favorites, rewards, notifications, support, FAQ,
   saved payment methods, receipt and reorder.
2. Generated menu operations use `/menu/categories` and `/menu/items/{id}`;
   the backend exposes `/categories` and `/menu/{id}`. Production Flutter uses
   the backend paths directly.
3. Generated account operations use singular `/customer/*`; profile,
   preferences and address backend routes use `/customers/me/*`. Generated
   security-session endpoints are not exposed by the current backend OpenAPI.
4. Generated order/quote operations use `/orders`, `/orders/{id}` and
   `/quotes*`; the current backend exposes `/orders/me*`, `/pricing/calculate`,
   `/cart*` and `/checkout`. Production Flutter manually adapts the latter.
5. Generated privacy and reauthentication operations use routes absent from
   the current backend OpenAPI; the backend instead exposes generic
   `/customers/me/privacy/requests` and consents. The production gateway calls
   the absent generated-style privacy routes.
6. `customer/README.md` says privacy uses the generated reauthentication
   operation, but generated schema presence does not make the backend route
   operational. The route must be added to the backend or the approved privacy
   UX/client contract must be adapted to the existing request API.

The modernization implementation must choose one authoritative OpenAPI, align
backend routes and semantics, regenerate the Dart client, and prevent raw HTTP
route strings outside the core API adapter. That alignment is a prerequisite
for calling any affected row complete.

## Architecture, session and router gaps

- The checked-in production entrypoint is `customer/lib/main.dart` ->
  `Week2App`, not `LaFavolaApp`; `LaFavolaApp` remains a debug-only prototype.
- The target `app/core/features/shared` architecture is not present. Most
  production behavior is concentrated in `week2_app.dart`,
  `week2_http_gateway.dart`, and the 2,600-line
  `customer_menu_experience.dart`.
- There is no Riverpod, GoRouter, encrypted secure storage, connectivity owner,
  shared pagination/mutation state, cart owner, unread-count owner, lifecycle
  restoration, or single-flight refresh coordinator.
- Named navigation does not encode menu item/order IDs in paths, so item,
  tracking, receipt and privacy request state are not cold-start deep-linkable.
- Guarding is incomplete and loses intent. Unknown routes silently become
  sign-in rather than a typed not-found route.
- The adaptive shell does not match the approved Home/Menu/Orders/Rewards/
  Account information architecture: it exposes Menu, Orders, Profile,
  Preferences and Privacy, with no Home or Rewards and no consolidated Account.
- Widget-local pending checkout/idempotency maps do not survive app restart and
  are not an authoritative cart/session restoration mechanism.

## Prioritized bounded implementation gaps

### P0 — release blockers

1. Freeze one backend OpenAPI contract, reconcile the route/semantic drift
   above, regenerate `la_favola_generated_api`, and add contract tests proving
   each modernization operation exists before expanding UI.
2. Implement the target app foundation: ProviderScope/Riverpod ownership,
   GoRouter guarded/deep-linkable routes with intent restoration, encrypted
   refresh-token storage, in-memory access token, startup restoration,
   single-flight refresh, connectivity and stable error mapping.
3. Replace the checkout-sheet pseudo-cart with a route-stable, multi-item,
   API-authoritative cart and explicit conflict/idempotent retry behavior.
4. Separate builder validation from quote creation and call the approved
   builder/pricing operations, including incompatibility, removal,
   unavailable-choice and stale-version recovery.
5. Make checkout, tracking, cancellation, receipt and reorder independently
   routeable; implement the missing reorder UI and payment recovery behavior.
6. Resolve account security/privacy API blockers before release. Privacy scope,
   reauthentication proof, retention/deletion wording and data handling require
   human legal/compliance and data-classification approval.
7. Establish traceable tests for every P0 journey across happy, validation,
   401/403/404/409/429/dependency/offline/reconnect/destructive states plus
   debug/release build and emulator smoke evidence.

### P1 — required planned journeys

1. Add feature slices and named routes for Favorites, Rewards, Notifications,
   Support, FAQ and Payment Methods using regenerated API operations.
2. Rebuild the approved Home/Menu/Orders/Rewards/Account adaptive navigation,
   including global cart, notification and active-order destinations.
3. Centralize shared state layouts and motion tokens; validate 320px, tablet,
   200% text, keyboard, semantics, Italian/English and reduced motion on every
   release route. Provider-specific notifications/payment activation remains a
   human/external gate.

### P2 — hardening and maintainability

1. Split the large Week2/menu files into feature data/domain/application/
   presentation boundaries and remove unreachable legacy prototype/admin code
   from customer release sources after regression parity is proven.
2. Add automated checks preventing raw UUID/internal-enum primary display and
   allowing support references only in expandable technical details.
3. Add pagination, cache age/stale indicators, analytics/observability hooks
   and route-state restoration only after their policy and privacy effects are
   approved.

## Human decisions and assumptions

- Assumption: checked-in Nest controllers plus `api/openapi.json` describe the
  current backend implementation more reliably than the generated customer
  package when they conflict. This is a feasibility classification, not an API
  design approval.
- Human approval is required for final scope/priority, timeline/budget,
  legal/compliance and privacy wording, data classification/storage,
  notification/payment provider activation, fiscal-document behavior, and any
  unresolved product trade-off (including reward eligibility and cancellation
  policy).
- Restaurant availability, pricing, fulfillment, reward, cancellation,
  payment and fiscal policy remain server-authoritative; this audit invents
  none of them.

## Validation record

Static validation used `rg` and direct file reads. Every path and symbol cited
above existed at inspection time. Controller routes were cross-checked against
`api/openapi.json`; generated coverage was cross-checked against
`packages/la_favola_generated_api/test/fixtures/operation-inventory.json`.
No format, analyzer, test, build, emulator, live API or provider operation was
executed, so historical test names are evidence of intent/coverage only, not a
current pass result.
