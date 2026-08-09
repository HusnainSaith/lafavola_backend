# La Favola Customer and Administration API Journey Guide

## 1. Purpose and source of truth

This guide explains how the La Favola customer application, administration application, support console, and delivery workflow use the backend. It reflects the current NestJS controllers, authorization decorators, generated OpenAPI contract, PostgreSQL schema, singleton restaurant migration, and S3 media implementation.

Base URL in local development: `http://localhost:3000`  
Swagger UI: `http://localhost:3000/api/docs`  
Authentication header: `Authorization: Bearer <accessToken>`

The application contains exactly one restaurant: **La Favola Restaurant**. PostgreSQL migration 23 prevents a second restaurant record. The restaurant API consequently exposes only `PATCH /restaurants`.

## 2. Roles and authorization model

Authentication is deny-by-default. Every route requires a valid access token unless its controller method is explicitly marked public. Resource ownership is checked in services in addition to route-level roles.

| Role | Application use | Main capabilities |
|---|---|---|
| `client` | Customer mobile application | Own profile, addresses, cart, checkout, orders, payments, delivery tracking, notifications, favorites, loyalty, privacy and support |
| `admin` | Administration application | Full restaurant configuration, catalog, staff, promotions, orders, payments, refunds, delivery, reporting, users, roles and permissions |
| `employee` | Restaurant/delivery operations | Assigned delivery status/location and collection of cash or terminal payments |
| `support` | Support console | Support queue, ticket claiming and ticket status management |
| `project_manager` | Internal account classification | No dedicated product journey currently; access must be granted with permissions |
| `developer` | Internal account classification | No dedicated product journey currently; access must be granted with permissions |
| `assistant` | Internal account classification | No dedicated product journey currently; access must be granted with permissions |
| `guest` | Limited/unauthenticated classification | Public catalog, FAQ and system routes only; normally no JWT is required for those routes |

`admin` is not a substitute for customer ownership on every endpoint. Customer endpoints derive the customer ID from the JWT and never trust a customer ID supplied in a request body.

## 3. Token lifecycle used by all applications

1. `POST /auth/register` creates a customer account and email-verification token.
2. `POST /auth/verify-email` consumes the emailed verification token.
3. `POST /auth/login` returns `data.accessToken`, `data.refreshToken`, and the safe user object.
4. Send the access token in the bearer header on protected calls.
5. `POST /auth/refresh` rotates the refresh token and returns a new token pair. The old refresh token cannot be reused.
6. `POST /auth/logout` revokes the supplied refresh token.
7. `POST /auth/forgot-password` always returns the same public response to prevent account discovery.
8. `POST /auth/reset-password` consumes the reset token, changes the password, and revokes active refresh sessions.
9. `POST /auth/resend-verification` requests another verification email for the authenticated account.

Public auth routes: register, login, refresh, forgot-password, reset-password and verify-email. Logout, resend-verification and all account data routes require authentication.

## 4. Customer mobile application journey

### 4.1 Startup and public discovery

| Route | Use |
|---|---|
| `GET /health` | Lightweight process liveness check |
| `GET /ready` | Database/configuration readiness check |
| `GET /categories` | Display active menu categories |
| `GET /categories/{id}` | Display one category |
| `GET /menu` | Browse the active menu; accepts filtering, sorting and pagination query fields |
| `GET /menu/search` | Search by restaurant, text and supported filters |
| `GET /menu/{id}` | Load a menu item with sizes, ingredients, image and restaurant data |
| `GET /faq` | List FAQ content |
| `GET /faq/{id}` | Read one FAQ entry |

The mobile client should cache the singleton restaurant UUID returned through menu/category data because many catalog and checkout records reference it.

### 4.2 Profile, avatar, preferences and privacy

| Route | Use |
|---|---|
| `GET /customers/me/profile` | Get or initialize the authenticated customer's profile |
| `PATCH /customers/me/profile` | Update date of birth, language and opt-in fields |
| `POST /media/upload` | Multipart avatar upload with `purpose=avatar`; S3 upload automatically updates the profile avatar URL |
| `GET /customers/me/preferences` | Get dietary/communication preferences |
| `PATCH /customers/me/preferences` | Update preferences |
| `GET /customers/me/privacy/consents` | Read consent audit history |
| `POST /customers/me/privacy/consents` | Record a consent grant or withdrawal and policy version |
| `GET /customers/me/privacy/requests` | List privacy requests |
| `POST /customers/me/privacy/requests` | Request export, restriction, correction or deletion |
| `POST /customers/me/privacy/requests/{id}/fulfill` | Execute supported owned privacy requests |

For an avatar, send multipart fields `file`, `purpose=avatar`, and optional `altText`. JPEG, PNG and WebP are accepted up to 5 MB.

### 4.3 Delivery addresses

| Route | Use |
|---|---|
| `GET /customers/me/addresses` | List owned active addresses |
| `POST /customers/me/addresses` | Create an address |
| `PATCH /customers/me/addresses/{id}` | Update an owned address or default selection |
| `DELETE /customers/me/addresses/{id}` | Remove/deactivate an owned address |

Save the returned address ID for checkout. Accessing another customer's address returns not found rather than revealing its existence.

### 4.4 Pizza configuration and authoritative pricing

| Route | Use |
|---|---|
| `GET /ingredients` | List ingredients available to authenticated users |
| `GET /ingredients/{id}` | Ingredient detail and extra price |
| `GET /option-groups` | List dough, sauce, cheese, topping or other option groups |
| `GET /option-groups/{id}` | Read choices and constraints for one group |
| `GET /pizza-builder/{menuItemId}` | Load builder rules for a customizable pizza |
| `POST /pizza-builder/build` | Validate a proposed custom pizza |
| `POST /pricing/calculate` | Calculate server-authoritative base, option and total prices |

The frontend may show immediate estimates, but must use server totals for cart and checkout. Prices are stored in minor currency units: `250` means EUR 2.50.

### 4.5 Cart

| Route | Use |
|---|---|
| `GET /cart` | Get or initialize the authenticated customer's active cart |
| `POST /cart/items` | Add a standard, modified or custom item |
| `PATCH /cart/items/{id}` | Change quantity or selected options |
| `DELETE /cart/items/{id}` | Remove an owned cart item |
| `DELETE /cart` | Clear the active cart |

Use menu-item, size, ingredient and option-choice IDs returned by discovery routes. Never calculate or submit a trusted final price from the client.

### 4.6 Promotions and coupons

| Route | Use |
|---|---|
| `GET /promotions` | Read promotions visible to authenticated users |
| `GET /promotions/{id}` | Promotion detail |
| `GET /coupons` | Read available coupon definitions where permitted |
| `GET /coupons/{id}` | Coupon detail |

Coupon codes are supplied during checkout. Eligibility, time windows, exclusions, stacking, usage limits and totals are evaluated by PostgreSQL-backed services.

### 4.7 Checkout, payment and receipt flow

1. Call `POST /checkout` with the owned cart, address, order type, coupon and payment method. It creates the order from authoritative database values.
2. For online SumUp payment, call `POST /payments/checkouts` with the owned order ID and follow the hosted checkout response.
3. Poll `GET /payments/orders/{orderId}/status` when returning from the provider. Provider state may be refreshed safely.
4. SumUp calls public `POST /payments/webhooks/sumup`; the backend verifies state with SumUp rather than trusting webhook content alone.
5. For cash/card on delivery, the employee/admin records collection through `POST /payments/orders/{id}/collect`.

Saved payment-reference routes for the customer:

| Route | Use |
|---|---|
| `GET /payments/methods` | List safe, owned provider references; no raw card data |
| `PATCH /payments/methods/{id}/default` | Set an owned method as default atomically |
| `DELETE /payments/methods/{id}` | Archive an owned method |

### 4.8 Orders, history and reorder

| Route | Use |
|---|---|
| `GET /orders/me` | Paginated owned order history |
| `GET /orders/me/{id}` | Owned order detail, totals and state |
| `POST /orders/me/{id}/reorder` | Revalidate available items/options and add them to the active cart |
| `POST /orders/me/{id}/cancel` | Cancel an owned order only while business rules allow it |

### 4.9 Delivery tracking

| Route | Use |
|---|---|
| `GET /deliveries/orders/{orderId}/tracking` | Customer-visible ETA, progress and latest coordinates |
| `GET /deliveries/orders/{orderId}/assignment` | Assignment detail when authorized |

Tracking is owner-scoped. The mobile UI maps backend stages to preparing, cooking, packing, driver assigned, en route and delivered.

### 4.10 Notifications

| Route | Use |
|---|---|
| `GET /notifications` | Paginated owned notifications |
| `GET /notifications/unread-count` | Badge count |
| `PATCH /notifications/{id}/read` | Mark one owned notification read |
| `POST /notifications/devices` | Register/update an FCM device token |
| `DELETE /notifications/devices/{id}` | Deactivate an owned device token |
| `GET /notifications/preferences/me` | Read notification preferences |
| `PATCH /notifications/preferences/me` | Update channel/type preferences |

### 4.11 Favorites and loyalty

| Route | Use |
|---|---|
| `GET /favorites` | List owned favorites |
| `POST /favorites` | Save a menu item/configuration |
| `POST /favorites/{id}/cart` | Revalidate and add a favorite to the cart |
| `DELETE /favorites/{id}` | Remove an owned favorite |
| `GET /loyalty/balance` | Current points balance |
| `GET /loyalty/history` | Point transaction history |
| `POST /loyalty/redeem` | Redeem points under configured rules |

### 4.12 Support, live chat and refunds

| Route | Use |
|---|---|
| `GET /support/tickets` | List owned conversations |
| `POST /support/tickets` | Open a support ticket |
| `GET /support/tickets/{id}` | Ticket detail and unread state |
| `GET /support/tickets/{id}/messages` | Paginated chronological messages |
| `POST /support/tickets/{id}/messages` | Send a persisted message |
| `PATCH /support/tickets/{id}/read` | Mark the customer side read |
| `GET /support/tickets/{id}/realtime-authorization` | Authorize the private AppSync channel |
| `POST /media/upload` | Upload support image/PDF using `purpose=support_attachment` and the ticket ID |
| `POST /refunds` | Request a refund for an owned order/payment |
| `GET /refunds/orders/{orderId}` | List refunds for an owned order |
| `GET /refunds/{id}` | Read an owned refund status |

Upload support files first, then include returned asset IDs in the message's `attachmentMediaIds`.

## 5. Administration application journey

### 5.1 Administrator sign-in and dashboard bootstrap

The admin uses `POST /auth/login`, stores the access/refresh tokens securely, then loads `GET /ready`, `GET /reports/sales`, `GET /reports/daily-revenue`, `GET /reports/popular-items`, and `GET /orders/admin/list` for dashboard state.

### 5.2 Singleton restaurant settings

| Route | Role | Use |
|---|---|---|
| `PATCH /restaurants` | `admin` | Update La Favola name, contact/address, timezone, delivery estimate/fee, minimum order, tax and active state |

There is intentionally no restaurant create, list, detail or delete route.

### 5.3 Staff management

| Route | Role | Use |
|---|---|---|
| `GET /staff` | `admin` | List staff, optionally filtered by the singleton restaurant ID |
| `POST /staff` | `admin` | Link a user to restaurant staff data |
| `DELETE /staff/{id}` | `admin` | Deactivate a staff member |

### 5.4 Catalog administration

Categories:

- `POST /categories` creates a category.
- `PATCH /categories/{id}` updates it.
- `DELETE /categories/{id}` deactivates/removes it.
- Public `GET /categories` and `GET /categories/{id}` verify presentation.

Ingredients:

- `POST /ingredients`, `PATCH /ingredients/{id}`, `DELETE /ingredients/{id}` are admin mutations.
- `GET /ingredients` and `GET /ingredients/{id}` provide authenticated catalog reads.

Menu items:

- `POST /menu` creates the item and sizes.
- `PATCH /menu/{id}` updates it.
- `DELETE /menu/{id}` archives it rather than destroying order history.
- Public `GET /menu`, `GET /menu/search`, and `GET /menu/{id}` verify the customer view.

Option groups:

- `POST /option-groups` creates dough/sauce/cheese/topping groups.
- `PATCH /option-groups/{id}` updates group rules.
- `POST /option-groups/{id}/choices` adds priced choices.
- `GET /option-groups` and `GET /option-groups/{id}` read configuration.

All catalog writes require `admin`. IDs must belong to La Favola Restaurant.

### 5.5 Multipart S3 media workflow

`POST /media/upload` accepts multipart form data and uploads directly to S3. Admin image purposes are `menu_image`, `category_image`, and `ingredient_image`. Required fields are `file`, `purpose`, `restaurantId`, and `targetId`; `altText` is optional. Successful uploads automatically attach the media asset to the target record.

The alternative large-client/direct-S3 workflow remains available:

1. `POST /media/uploads` authorizes a short-lived presigned PUT.
2. The client PUTs bytes to S3 using the returned headers.
3. `POST /media/{id}/finalize` verifies S3 metadata and activates the asset.
4. `DELETE /media/{id}` deletes an owned object using its server-trusted key.

### 5.6 Promotions and coupons administration

| Resource | Create | Read | Update | Remove/deactivate |
|---|---|---|---|---|
| Promotions | `POST /promotions` | `GET /promotions`, `GET /promotions/{id}` | `PATCH /promotions/{id}` | `DELETE /promotions/{id}` |
| Coupons | `POST /coupons` | `GET /coupons`, `GET /coupons/{id}` | `PATCH /coupons/{id}` | `DELETE /coupons/{id}` |

Mutations require `admin`. Configure dates, limits, priority, stacking, conditions and exclusions carefully; the examples in the requirements document are not complete executable promotion specifications.

### 5.7 Order, payment, refund and delivery operations

| Route | Role | Use |
|---|---|---|
| `GET /orders/admin/list` | `admin` | Filter and paginate all orders |
| `PATCH /orders/admin/{id}/status` | `admin` | Advance restaurant order status |
| `POST /payments/orders/{id}/collect` | `admin`, `employee` | Record cash or external terminal payment |
| `PATCH /refunds/{id}/approve` | `admin` | Approve and execute an eligible refund |
| `POST /deliveries/orders/{orderId}/assign` | `admin` | Assign a driver |
| `GET /deliveries/orders/{orderId}/assignment` | authorized owner/staff | Read assignment |
| `PATCH /deliveries/orders/{orderId}/status` | `admin`, `employee` | Advance assigned delivery state |
| `PATCH /deliveries/orders/{orderId}/location` | `admin`, `employee` | Publish driver coordinates |

The backend serializes competing assignments, transitions and refunds to prevent double processing.

### 5.8 FAQ administration

- `POST /faq` creates an article.
- `PATCH /faq/{id}` updates it.
- `DELETE /faq/{id}` removes/deactivates it.
- Public `GET /faq` and `GET /faq/{id}` show the customer result.

### 5.9 Reporting

| Route | Role | Use |
|---|---|---|
| `GET /reports/sales` | `admin` | Recognized sales, refunds, net revenue, counts and averages |
| `GET /reports/daily-revenue` | `admin` | Date series in minor units |
| `GET /reports/popular-items` | `admin` | Ranked sold quantities/revenue |

Use date and restaurant query filters documented by Swagger. Financial reports derive from persisted paid/refunded order state, not frontend totals.

## 6. Support staff journey

1. Log in with the `support` role.
2. `GET /support/agent/queue` lists filtered tickets.
3. `POST /support/agent/tickets/{id}/claim` atomically claims an unassigned ticket.
4. `GET /support/tickets/{id}` and `GET /support/tickets/{id}/messages` load the conversation.
5. `POST /support/tickets/{id}/messages` replies.
6. `PATCH /support/tickets/{id}/read` updates unread state.
7. `GET /support/tickets/{id}/realtime-authorization` authorizes live updates.
8. `PATCH /support/agent/tickets/{id}/status` resolves, closes or updates the ticket.

These agent routes allow `admin` or `support`; they do not grant support staff unrelated administration privileges.

## 7. Employee/driver journey

1. Admin creates the underlying user and staff record.
2. Admin assigns an order using `POST /deliveries/orders/{orderId}/assign`.
3. Driver reads `GET /deliveries/orders/{orderId}/assignment`.
4. Driver advances delivery through `PATCH /deliveries/orders/{orderId}/status`.
5. Driver publishes location with `PATCH /deliveries/orders/{orderId}/location`.
6. If payment is due on delivery, driver/admin calls `POST /payments/orders/{id}/collect`.

Only the assigned driver or admin may perform protected assignment operations.

## 8. Identity, roles and permissions administration

User administration is permission-based:

- `POST /users`, `POST /users/with-permissions`
- `GET /users`, `GET /users/{id}`
- `PATCH /users/{id}`, `DELETE /users/{id}`
- `POST /users/{id}/permissions`, `GET /users/{id}/permissions`
- `GET /users/available-features`
- `GET /users/available-features/{feature}/actions`

Role administration requires admin plus matching role permissions:

- `POST /roles`, `GET /roles`, `GET /roles/{id}`, `PATCH /roles/{id}`, `DELETE /roles/{id}`

Permission catalog administration:

- `POST /permissions`, `GET /permissions`, `GET /permissions/{id}`
- `GET /permissions/resources`, `GET /permissions/actions`, `GET /permissions/by-resource`
- `PATCH /permissions/{id}`, `DELETE /permissions/{id}`

Role-permission links require admin:

- `POST /role-permissions/{roleId}`
- `GET /role-permissions/{roleId}`
- `DELETE /role-permissions/{roleId}/{permissionId}`

Do not let the mobile client choose its role during registration. Customer registration always resolves the server-controlled `client` role.

## 9. Common response and error behavior

Successful data is processed by the global response interceptor. Errors use a safe structure containing `success`, `message`, `error`, `statusCode`, `timestamp`, `path`, optional validation `details`, and optional `requestId`.

| Status | Meaning |
|---|---|
| `400` | DTO validation, invalid state or database check constraint |
| `401` | Missing, malformed, expired or invalid access token |
| `403` | Authenticated but missing role/permission |
| `404` | Missing or non-owned resource |
| `409` | Duplicate or conflicting resource/state |
| `429` | Rate limit/throttle exceeded |
| `500` | Unexpected internal failure; response is sanitized |
| `503` | Required external provider/storage unavailable |

Never retry non-idempotent mutations blindly. Refresh an expired token once, then retry with the new access token. Preserve `x-request-id` when supplied for log correlation.

## 10. End-to-end customer sequence

`register -> verify -> login -> profile/avatar -> address -> categories/menu/search -> pizza-builder/pricing -> cart -> checkout -> SumUp or pay-on-delivery -> order history -> tracking/notifications -> favorite/reorder -> support/refund -> logout`

## 11. End-to-end administrator sequence

`login -> readiness/reports -> patch singleton restaurant -> create staff -> categories/ingredients/menu/options -> multipart S3 images -> promotions/coupons -> order queue/status -> payment/refund -> delivery assignment -> support oversight -> FAQ -> users/roles/permissions -> reports -> logout`

## 12. Known scope qualifications

The backend covers the core functional requirements, but these items are not automatically proven by route availability:

- Google and Apple login remain optional and are not complete provider integrations.
- Real SMTP, AWS S3, SumUp, AppSync and Firebase behavior requires valid provider credentials and environment acceptance tests.
- BOGO, family-combo, free-item and student discounts require final business definitions.
- Loyalty economics and legal privacy-retention policy require product/legal decisions.
- Responsive UI, progress bars, animations, mobile builds and app-store submission are frontend/release responsibilities.

The generated `openapi.json` remains the machine-readable request-schema reference. This guide is the human workflow and access reference.
