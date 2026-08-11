# Admin tablet rebuild plan

## Outcome

Replace the current visual-prototype shell with an industry-standard,
feature-first Flutter admin application connected to every legitimate
restaurant-admin backend capability. Backend gaps discovered during the route
audit are implemented with restaurant ownership, role/permission checks,
validation, Swagger documentation, and tests.

## Implementation sequence

1. Freeze the route/screen matrix and regenerate Swagger from source.
2. Add the missing dashboard, refund queue, delivery board, media library, and
   audit read contracts; correct authorization/documentation drift.
3. Introduce Riverpod, GoRouter, Dio, connectivity, correlation/idempotency,
   typed failures, secure session restoration, and a declarative permission
   model.
4. Replace the monolithic `main.dart` with `app/core/shared/features` packages
   and an accessible responsive tablet shell.
5. Deliver vertical slices in operational order: auth/dashboard; orders,
   payments/refunds and deliveries; support/notifications; catalogue/media;
   offers/FAQ; staff/users/RBAC; restaurant/reports/audit.
6. Extend the existing private Stitch project for all canonical workspaces and
   map the accepted interaction patterns into native Flutter components.
7. Run deterministic backend and Flutter suites, regenerate contract evidence,
   build Android, and smoke-test on a safe emulator backend.

## Acceptance criteria

- No runtime text describes the app as a prototype or shows simulated business
  figures.
- Every matrix row has a dedicated, domain-aware screen or is explicitly
  excluded; no raw JSON payload editing is exposed to staff.
- Session refresh, navigation guards, capability-based action states,
  connectivity, pagination, validation, confirmation, conflicts and retries
  are implemented and tested.
- All administrative writes are scoped to the authenticated staff restaurant.
- Backend lint/build/unit/e2e and Swagger generation pass.
- Flutter format/analyze/unit/widget/integration and Android build pass.
- No secrets or production credentials are committed or embedded.

## Release boundary

This rebuild is implemented and verified locally/against an isolated QA data
surface first. Publishing a replacement APK or deploying backend changes to
production remains a separate production action after verification and a
backup/rollback check.
