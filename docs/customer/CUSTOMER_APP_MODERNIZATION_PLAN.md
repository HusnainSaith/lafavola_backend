# Customer app modernization plan

Status: implementation baseline — 2026-08-12

## Objective

Refactor the La Favola customer Flutter application into the same production
architecture family as the admin tablet app while preserving the customer
brand, public browsing, authenticated ownership boundaries, and the existing
server-authoritative pricing and fulfilment contracts.

The result must not expose raw database identifiers, invent restaurant policy,
or represent a non-fiscal order receipt as a legal invoice.

## Architecture

```text
lib/
  app/                 ProviderScope, router, adaptive shell, lifecycle
  core/
    api/               HTTP transport, stable errors, refresh coordination
    connectivity/      online/offline state
    session/           encrypted refresh token and session restoration
    state/             reusable async/pagination/mutation state
    theme/             semantic tokens, theme, motion preferences
  features/<feature>/
    data/               API repositories and DTO mapping
    domain/             immutable customer-facing models
    application/        Riverpod controllers/providers
    presentation/       routes, screens and feature widgets
  shared/               cross-feature UI primitives
```

Riverpod owns session, locale, connectivity, cart, unread count and feature
state. GoRouter owns guarded/deep-linkable navigation. Secure storage contains
only the rotating refresh token; access tokens remain in process memory.

## Information architecture

Primary navigation:

1. Home — restaurant status, continue order, popular items and active order.
2. Menu — category/search/filter, item detail, pizza builder and cart.
3. Orders — history, detail, tracking, cancellation, reorder and receipt.
4. Rewards — balance, history and eligible redemption.
5. Account — profile, addresses, payment methods, notifications, security,
   privacy, help/FAQ, support and language.

Global destinations: cart, notifications, active-order tracking, sign in,
registration, verification and recovery.

## Journey and API coverage

| Journey | Customer outcome | API contract |
|---|---|---|
| Public browse/search | Find real available menu items without signing in | `GET /menu`, `GET /menu/search`, `GET /menu/:id` |
| Builder | Configure only valid choices with clear min/max feedback | `GET /pizza-builder/:id`, `POST /pizza-builder/build`, `POST /pricing/calculate` |
| Cart | Add/edit/remove, survive route changes, recover conflicts | `/cart`, `/cart/items`, `/pricing/calculate` |
| Fulfilment | Choose delivery/pickup, address and restaurant-local slot | `/restaurant`, `/restaurant/availability` |
| Checkout | Review authoritative totals and place idempotently | `POST /checkout`, optional `/payments/checkouts` |
| Order lifecycle | Confirmation, server-clock ETA, progress and recovery | `/orders/me`, `/orders/me/:id` |
| After-order | Cancel when eligible, reorder and read non-fiscal receipt | `/orders/me/:id/cancel`, `/reorder`, `/receipt` |
| Favorites | Save configurations and move them to cart | `/favorites`, `/favorites/:id`, `/favorites/:id/cart` |
| Rewards | Read balance/history and redeem only eligible rewards | `/loyalty/balance`, `/history`, `/redeem` |
| Notifications | Read, mark read and manage preferences/devices | `/notifications*` |
| Support | Create/read tickets and exchange messages | `/support/tickets*` |
| Help | Browse searchable public FAQ | `/faq` |
| Account | Profile, addresses, preferences and sessions | `/customers/me/*` |
| Privacy | Reauthenticate and request export/deletion | `/customers/me/privacy/*` |
| Payment methods | Read/default/remove configured methods | `/payments/methods*` |

## State contract

Every data surface implements initial loading, pull-to-refresh, content, empty,
validation, offline-cached/offline-unavailable, dependency unavailable,
unauthenticated, forbidden, not-found, conflict/stale version, rate-limited,
retryable failure and destructive-confirmation states. Mutations are disabled
while in flight and preserve an idempotent retry path where the backend supports
one.

## Visual and interaction system

- Semantic palette continues the public-site espresso, terracotta, warm canvas,
  cream, sand, success, warning, error and information roles.
- Lora is limited to expressive headings; Poppins is used for controls and body.
- Compact, medium and expanded breakpoints are 600 and 1024 logical pixels.
- Touch targets are at least 48dp; primary checkout/order actions are 56dp.
- Cards, fields, sheets, chips, badges, timelines, price rows, quantity controls,
  skeletons and state panels use one shared component family.
- No raw UUID, correlation identifier or internal enum is primary user content.
  A support reference may appear only in an expandable technical-detail region.

## Motion

Motion communicates hierarchy or state:

- route content: 220ms fade/8px rise;
- cart/favorite mutation: 180ms scale/fade confirmation;
- bottom sheets: platform transition with focus retained;
- order status: 300ms cross-fade and progress interpolation;
- skeleton to content: 180ms cross-fade;
- badges: 160ms size/fade.

All motion is interruptible and uses `MediaQuery.disableAnimations` to provide
instant state changes with identical content and focus behavior.

## Acceptance evidence

- Every row above has a production route and API-backed repository/controller.
- Router guards restore the intended destination after authentication.
- Session refresh is single-flight and refresh tokens are encrypted at rest.
- Italian and English cover all release routes and semantic labels.
- 320px and tablet layouts, 200% text, keyboard/focus, screen-reader semantics,
  offline/reconnect and normal/reduced-motion paths pass.
- Format, analyze, unit/widget/integration tests, debug/release build checks and
  Android emulator smoke pass before release claims.

