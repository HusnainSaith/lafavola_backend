# Admin API coverage matrix

Verified locally on 2026-08-11 against a migrated PostgreSQL database and the
generated `api/openapi.json`. La Favola is a single-restaurant product; the
database migration `1700000000023-EnforceSingleRestaurant` enforces that fact.
The app never presents a restaurant switcher. Internal restaurant IDs remain
part of authorization and ownership checks.

| Feature | `/api/v1` contract | Flutter surface | Local status |
| --- | --- | --- | --- |
| Session | login, refresh, logout, forgot password | Sign-in, recovery, secure refresh, expiry | Complete |
| Dashboard | `GET /admin/dashboard/summary` | Live operational KPIs and quick links | Complete |
| Orders and payment | admin list/detail/status, on-delivery collection | Queue, detail, timeline, state actions, guarded collection | Complete |
| Refunds | create, per-order reads, admin queue, approve | Order refund request and finance approval queue | Complete |
| Deliveries | admin queue, dispatch board, driver CRUD, assignment, tracking, status, location | Order and named-driver selectors, driver directory/editor and state actions | Complete; no raw UUID entry or display |
| Support | agent queue, claim, ticket, messages, read, status | Conversation-first support desk | Complete |
| Catalogue | menu and categories CRUD | Typed catalogue/category editor | Complete |
| Ingredients | CRUD with dietary and allergen fields | Typed ingredient editor | Complete |
| Options | group and choice CRUD | Typed group/choice editor | Complete |
| Pizza builder | admin rule CRUD and customer configuration preview | Rule editor plus customer-view preview | Complete |
| Offers | promotion and coupon CRUD | Typed offer editors | Complete |
| FAQ | CRUD | Typed question/answer editor | Complete |
| Media | admin list, direct upload, delete | Media library, target selection and file upload | Complete; provider upload needs configured S3 |
| People | users, direct permissions, staff CRUD | Customer-filtered users, user selector for staff, staff and direct-permission editors | Complete |
| Access | roles, permissions, role assignments | RBAC matrix with inherited permissions protected | Complete |
| Restaurant | singleton profile and weekday hours | La Favola profile/hours settings | Complete |
| Reports | sales, daily revenue, popular items | Date filters, KPIs, chart/table panels | Complete |
| Notifications | inbox, detail, unread count, devices, preferences | Inbox detail, preference and device management | Complete; registration needs an FCM device token |
| Audit | restaurant-scoped paginated read | Read-only activity screen | Complete |

## Intentional exclusions

Customer profile, addresses, carts, checkout, favourites, saved payment
methods, loyalty redemption, customer order history/reorder/cancel, privacy
requests, OAuth callback endpoints, provider webhooks, worker routes and raw
driver GPS publishing are not admin-tablet destinations.

## Contract and fixture evidence

The regenerated local `api/openapi.json` exposes 183 operations. The isolated
PostgreSQL API-seed test migrates a fresh database, authenticates as an admin,
copies all 5 public-site categories and all 48 public menu products, and creates
representative ingredients, options, FAQ, offers, driver, customer, POS,
delivery and support data through HTTP. It runs the fixture twice to prove it
is idempotent. Deployment status must be checked independently at release time.
