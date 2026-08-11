# La Favola Android Tablet Admin App — Original Prototype Plan

> Superseded on 2026-08-11 by `ADMIN_APP_REBUILD_PLAN.md`,
> `ADMIN_API_COVERAGE_MATRIX.md`, and
> `../architecture/ADMIN_FLUTTER_ARCHITECTURE.md`. This file remains as the
> historical baseline and must not be used to claim rebuild completion.

## Objective and boundary

Create a production-grade Flutter Android tablet application in a new sibling
`admin/` workspace. It is a staff-only operational console for the NestJS API
in `api/`; it does not duplicate the public Astro site or expose customer-owned
data/actions where the API has no administrative contract.

Primary target: Android tablets in landscape at 1280 × 800, with safe support
for 1024 × 600 and portrait/reduced-width layouts. The app will compile for
Android first; web and iOS are intentionally out of the first release scope.

## Existing-contract inventory

| Admin capability | API contract | App area |
| --- | --- | --- |
| Sign-in, token refresh, logout | `POST /auth/login`, `/auth/refresh`, `/auth/logout` | Session gate |
| Orders and status | `GET /orders/admin/list`, `PATCH /orders/admin/:id/status` | Orders queue and status actions |
| Cash collection and refunds | `POST /payments/orders/:id/collect`, `POST /refunds`, `GET /refunds/orders/:orderId`, `PATCH /refunds/:id/approve` | Order detail / refunds |
| Delivery dispatch | `POST /deliveries/orders/:id/assign`, `GET /deliveries/orders/:id/assignment`, `PATCH /deliveries/orders/:id/status` | Dispatch |
| Support queue | `GET /support/agent/queue`, claim/status and ticket-message routes | Support |
| Menu catalogue | categories, ingredients, `menu`, option groups and choices CRUD routes | Menu |
| Promotions | promotions and coupons CRUD routes | Offers |
| Restaurant and media | `PATCH /restaurants`, media upload/finalize/delete routes | Settings / media |
| Staff and access control | staff, users, roles, permissions and role-permissions routes | Team & access |
| Reporting | sales, daily revenue and popular items routes | Reports |
| Notifications | notifications list/read, preferences and device routes | Inbox / preferences |

Customer-only contracts (profile, address book, cart, checkout, favourites,
loyalty, payment methods, and `orders/me`) are not exposed in the admin app.
They retain their API ownership checks and are not a substitute for missing
administrative reporting/search endpoints.

## Product architecture

- Flutter stable, Material 3, Android min SDK selected by the current Flutter
  template; portrait and landscape supported.
- Feature-first modules with Riverpod state/notifiers, `go_router` route guard,
  Dio HTTP client, generated OpenAPI DTOs, secure token storage, and injectable
  environment configuration (`--dart-define=API_BASE_URL=...`).
- Access and refresh tokens stay in encrypted platform storage. No API secret,
  AWS credential, or privileged database credential belongs in the app.
- A single authenticated API client adds `Authorization: Bearer`, serializes one
  refresh attempt, logs out on refresh failure, and maps API errors to
  actionable Italian UI messages without exposing server internals.
- Mutations use visible pending/failed/success states, confirmation for
  destructive actions/refunds/status transitions, idempotency keys where the
  API accepts them, and refetch after success. No optimistic financial or order
  state is treated as final until the API confirms it.
- Connectivity-aware reads cache only low-risk operational lists locally; all
  changes require a live connection. Pending actions are never silently replayed
  after an authentication or business-rule failure.

## Visual system

The public-site design tokens are the source of truth:

| Token | Value | Admin use |
| --- | --- | --- |
| Espresso | `#774E32` | primary navigation and primary actions |
| Coffee | `#6F4E37` | headers, links and focus emphasis |
| Terracotta | `#B7825F` | secondary action / status emphasis |
| Dark terracotta | `#925E3E` | destructive attention and selected states |
| Sand | `#C0A891` | dividers and quiet surfaces |
| Sand light | `#F4EDE6` | app background / filter wells |
| Paper | `#FFFAF5` | content surface |
| Ink | `#3D2B20` | body text |

Use Poppins for controls/data density and Lora only for restrained editorial
headings. Meet AA contrast, preserve 48 dp minimum touch targets, show visible
keyboard focus, support text scaling, do not rely on colour alone for status,
and use short non-essential motion only with a reduced-motion setting.

## Screen and state matrix

1. **Sign-in / session recovery** — email/password, loading, invalid login,
   expired session, offline, and logout.
2. **Operations dashboard** — live order summary, pending payment/refund/support
   counts, quick actions, loading/empty/error/stale-data states.
3. **Orders workspace** — filterable status lanes/table, search, pagination,
   no-results, retry, and order-detail split view.
4. **Order detail / fulfilment** — gated until an admin-owned order-detail API
   exists; the customer-owned `/orders/me/:id` route must never be repurposed.
5. **Delivery dispatch** — assignment, driver status, tracking state, failed
   update/retry and permission-disabled variants.
6. **Support desk** — agent queue, claim/status, threaded ticket messages,
   unread/read states, composer validation and connection fallback.
7. **Catalogue overview** — categories/menu search, availability and media
   status, empty/onboarding/loading/error states.
8. **Menu editor** — item form, price/options/ingredients, validation,
   unsaved-change guard, create/edit/delete confirmations.
9. **Ingredients and option groups** — separate manageable tables/forms with
   dependency-aware delete errors.
10. **Offers** — promotions and coupons list/editor, active/inactive state,
    date/validation errors and destructive confirmation.
11. **Media library** — select/upload/finalize/delete lifecycle, upload progress,
    retry and unsupported file/error handling.
12. **Team and access** — staff, users, roles and permission assignment,
    least-privilege warnings and self-lockout prevention UI.
13. **Restaurant settings** — restaurant profile/hours/settings mutation with
    review-before-save and mutation feedback.
14. **Reports** — sales, daily revenue and popular items, date filtering,
    zero-data, loading and export-ready presentation (CSV export only after a
    verified API/client contract exists).
15. **Notification inbox and preferences** — read/unread, deep links to owned
    operational records, preference update and device registration.

## Stitch design work

Create a **private** Stitch project for this Android tablet app and establish
the design system above. Generate and inspect the canonical tablet screens:
sign-in, dashboard, orders/detail, menu editor, delivery dispatch, support,
team/access, reports, and settings. The Flutter implementation is based on the
approved screen behaviour and tokens, not generated HTML. Every canonical
screen must show normal, loading, empty, permission-denied, API-error and
reduced-motion behaviour where applicable.

## Delivery sequence

1. Create private Stitch design system and canonical tablet screens; document
   screen/state evidence.
2. Bootstrap `admin/` Flutter workspace with lint rules, flavourable API base
   URL, theme, routing, secure session/client, error model and test harness.
3. Implement authentication and shell/navigation; then dashboard/orders/order
   detail/refunds/delivery as the operational slice.
4. Implement support and notification inbox.
5. Implement catalogue, media and offers.
6. Implement staff/RBAC, restaurant settings and reports.
7. Generate/update typed client models from `api/openapi.json`; add contract
   tests for every mapped endpoint and fixtures for failure states.
8. Run Flutter unit/widget/integration tests, Android build, accessibility
   checks and tablet emulator/device validation. Only deploy after explicit
   production/MDM distribution approval.

## Acceptance criteria

- Every endpoint in the admin capability inventory has a traceable screen,
  repository action and success/error/empty/loading state.
- No customer-only endpoint is used as an admin workaround.
- Role restriction and API `403` behaviour visibly disables/guards actions.
- Token refresh, logout, offline failure, pagination/filter reset and mutation
  retry are covered by automated tests.
- `flutter analyze`, formatting check, unit/widget tests and Android release
  build pass; tablet smoke tests cover sign-in, order status, delivery,
  catalogue edit, support reply, staff permissions and reports.
- The app has no hard-coded production credentials, API keys or database values.

## Decisions and gates

- The API has no dedicated admin order-detail read, customer search, unified
  dashboard aggregate, restaurant-settings read, business-hours API, financial
  export, broadcast-message composer, or authenticated app-level realtime
  stream contract. The initial dashboard uses available list/report contracts;
  unsupported screens remain gated until a backend contract is implemented.
- Staff has list/create/deactivate only, and option choices have add-only
  behaviour. The tablet must not display edit/delete controls that the API does
  not support. Payment-status reads are customer-owned, so the initial payment
  workspace is limited to authorised collection/refund contracts.
- Actual roles/permissions and the desired Android distribution method (managed
  Play, private APK/MDM, or internal testing) need restaurant-owner approval
  before release. They do not block local implementation.
- The sender identity must remain separate from the Flutter app: SES/API secrets
  stay on the backend only.

## Initial implementation evidence — 9 August 2026

The first implementation slice is present in `admin/`:

- Android Material 3 tablet shell, responsive rail/drawer navigation, branded
  Poppins/Lora typography, and dashboard normal/loading/offline/denied/error
  states;
- live `/auth/login`, `/auth/refresh`, and `/auth/logout` client foundation;
  only an API role named `admin` may enter the shell;
- encrypted refresh-token storage, refresh-token rotation, in-memory access
  token, a 15-second transport timeout, and Italian error mapping;
- a central registry for every current admin-owned API route listed above;
  customer-owned API paths are absent by design;
- widget and HTTP-contract tests for authentication, timeout handling, tablet
  layouts, large text scaling, and safe operational states.

The feature workspaces remain deliberately inactive until their repository and
screen tests are implemented. A route registry alone is not treated as CRUD
completion: orders, deliveries, support, catalogue, offers, media, access,
settings, reports, and notifications require the delivery slices in the
sequence above. The Android debug build was started locally but exceeded the
two-minute command cap without producing an APK; it remains a build gate.
