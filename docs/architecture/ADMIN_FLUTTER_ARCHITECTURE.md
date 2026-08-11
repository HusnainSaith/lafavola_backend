# La Favola admin tablet architecture

Status: implemented and locally verified on 2026-08-11.

## Product boundary

La Favola is the only restaurant. There is no tenant selector, restaurant
switcher or cross-restaurant reporting. Backend staff ownership checks and the
database singleton constraint remain mandatory defense in depth.

## Runtime structure

```text
lib/
  app/                  ProviderScope bootstrap, GoRouter and responsive shell
  core/
    api/                Dio API gateway, route registry and error/envelope map
    config/             dart-define environment configuration
    session/            Android Keystore-backed refresh-token storage
    theme/              Material 3 La Favola tokens
  shared/presentation/  reusable typed CRUD fields and state layouts
  features/
    access/ audit/ auth/ catalogue/ dashboard/ deliveries/ finance/
    media/ navigation/ notifications/ offers/ orders/ reports/
    restaurant/ support/
```

The code is feature-first: each business workspace owns its presentation and
workflow state. A single API gateway centralizes transport, bearer headers,
correlation IDs, idempotency headers, response-envelope decoding, timeout
mapping and serialized token refresh. This project deliberately avoids a
repository class per HTTP call where it would only proxy the gateway; complex
shared server state uses Riverpod providers, while dialog/form controllers
remain local to their feature.

## State, navigation and session

Riverpod owns session restoration, authentication, connectivity, dashboard,
reports, refund queue, media and audit async state. Stateful feature screens
own short-lived filters, selection and form input; every successful mutation
reloads authoritative server data. Duplicate submissions are disabled while a
mutation is in flight.

GoRouter protects the shell and returns signed-out sessions to login. Only an
API-authenticated `admin` role may create a local session. Access tokens remain
in memory, refresh tokens use `flutter_secure_storage`, and a single failed
refresh clears the local session.

## API and error contract

Release builds receive only `API_BASE_URL`, normally
`https://api.lafavolabrescia.it/api/v1/`. No database, AWS, mail, payment or
signing secret is compiled into Flutter. The API gateway converts 401, 403,
409, validation and transport failures into Italian operational messages.
Backend JWT, roles, permissions, ownership and the singleton restaurant
constraint remain authoritative.

## Design and accessibility

The private Stitch project is `projects/8916945245491125542`; its design system
is `assets/c7d3c1e01ded48d7a048f00bb604679f`. Flutter uses Material 3, Poppins,
Lora and the public-site espresso/terracotta/sand palette. Controls are at
least 48 dp, status uses icon plus text, forms have persistent labels, narrow
screens use a drawer/single column, and landscape tablets use a navigation
rail/split views.

## Verification contract

- Backend: format/lint/build, full non-database suite, DB-gated integration
  compilation, regenerated Swagger and route inventory.
- HTTP: migrated isolated PostgreSQL, real admin authentication, read queues,
  reports and complete temporary CRUD round-trips.
- Flutter: format, analyzer, unit/widget tests and native Android integration
  test opening every shell destination.
- Release: signed APK verification and live Swagger compatibility check.
