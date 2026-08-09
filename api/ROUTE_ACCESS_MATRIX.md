# Route Access Matrix

Authentication is deny-by-default through the global JWT guard. Only routes marked `@Public()` bypass authentication. Global role and permission guards evaluate route metadata after authentication.

The existing role vocabulary is retained: `client` is the customer role, `employee` covers delivery/restaurant operations pending a dedicated delivery role decision, `support` is support staff, `project_manager` is manager, and `admin` is administrator.

| Controller | Public | Customer/authenticated | Staff/support/admin |
|---|---|---|---|
| system | root, health, readiness | - | - |
| privacy | - | own consent history and privacy requests | - |
| auth | register, login, refresh, forgot/reset password | logout | — |
| users | — | — | permission-protected identity administration |
| customers | — | own profile/preferences | — |
| addresses | — | own addresses | — |
| restaurants | list/detail | — | admin mutations |
| staff | — | — | admin only |
| menu | list/search/detail | — | admin mutations |
| categories | list/detail | — | admin mutations |
| ingredients | — | authenticated reads | admin mutations |
| option-groups | — | authenticated reads | admin mutations |
| pricing | — | calculate | — |
| pizza-builder | — | rules/build | — |
| carts | — | own cart/items | — |
| promotions | — | authenticated reads | admin mutations |
| coupons | — | authenticated reads | admin mutations |
| checkout | — | own checkout | — |
| orders | — | own history/detail/cancel | admin list/status |
| payments | — | own methods/intents | admin collection |
| refunds | — | own order refund request/history | admin approval |
| deliveries | — | authenticated tracking | admin assignment; admin/employee location update |
| notifications | — | own notifications/devices/preferences | — |
| favorites | — | own favorites | — |
| loyalty | — | own balance/history/redemption | — |
| support | — | own tickets/messages | admin/support queue and updates |
| faq | list/detail | — | admin mutations |
| reports | — | — | admin only |
| media | — | authenticated upload request | provider/object ownership enforced by service |
| roles | — | — | admin plus permissions |
| permissions | — | — | permission-protected administration |
| role-permissions | — | — | admin only |
| audit | — | — | no exposed routes currently |

## Ownership enforcement

Customer IDs are sourced from the authenticated principal, not request bodies. Address, cart, order, favorite, notification, payment, support, and loyalty services query using the authenticated customer ID. Missing or foreign resources use not-found behavior to avoid revealing another customer's resource existence. Delivery location changes require `admin` or `employee`; support queue access permits `support` without granting general administrator access.
