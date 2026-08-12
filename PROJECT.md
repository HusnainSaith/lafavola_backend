# La Favola project

Status: active local implementation

La Favola is a single-restaurant product consisting of a NestJS API, a public
site, an Android admin tablet application, and a Flutter customer application.
This durable record currently covers the customer-application modernization
phase defined by `docs/customer/CUSTOMER_APP_MODERNIZATION_PLAN.md`.

## Current objective

Complete and locally verify the customer Flutter application against the real
customer API contract, using the same architecture family as the admin app:
Riverpod state, GoRouter navigation, encrypted refresh-token storage,
single-flight refresh, responsive and accessible presentation, purposeful
motion with reduced-motion parity, and Italian/English localization.

## Scope boundary

- In scope: `customer/`, `packages/la_favola_generated_api/`, narrowly required
  customer-facing `api/` contracts/tests, and customer delivery evidence.
- Protected: concurrent admin work, credential CSV files, production systems,
  public/existing design resources, and unrelated API behavior.
- External design work is additive only in the authorized private Stitch
  destination recorded in `DECISIONS.md`; production deployment is excluded.

## Governing artifacts

- `docs/customer/CUSTOMER_APP_MODERNIZATION_PLAN.md`
- `customer/README.md`
- `docs/architecture/ADMIN_FLUTTER_ARCHITECTURE.md`
- `docs/admin/ADMIN_API_COVERAGE_MATRIX.md`

Approved decisions outrank the implementation baseline. Any remaining manual,
provider, credential, risk-acceptance, or production action stays gated.
