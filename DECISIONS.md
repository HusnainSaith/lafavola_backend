# La Favola decisions

Updated: 2026-08-12

## D-001 — Customer implementation baseline

Status: active

The customer app follows `docs/customer/CUSTOMER_APP_MODERNIZATION_PLAN.md` and
the architecture family documented in
`docs/architecture/ADMIN_FLUTTER_ARCHITECTURE.md`. Server-authoritative pricing,
fulfilment, ownership, and order behavior remain unchanged. A non-fiscal order
receipt must not be represented as a legal fiscal invoice.

## D-002 — Stitch safety target correction

Status: active safety determination

The remembered project `projects/410668225356694970` is currently public and
contains 32 screens. It must not be mutated under the private/additive customer
design boundary. The bounded design pass uses the verified private owner project
`projects/15736357098573745733` (`La Favola Product UI`) and design-system asset
`assets/8453361971917840780`. Work is additive only, capped at 18 new screens,
with no edit, delete, publish, or share action. The root project coordinator
owns this external pass and its evidence ledger.

## D-003 — Current release boundary

Status: active

This phase may implement and validate locally but may not deploy to production,
publish an app, activate paid/provider integrations, request credentials, or
accept a release-blocking risk without explicit human approval.
