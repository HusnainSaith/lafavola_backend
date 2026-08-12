# La Favola tasks

Updated: 2026-08-12

## Customer modernization

- [ ] CUS-001 — Finish the baseline feature/API/route/state coverage audit for
  every journey in the customer modernization plan. Owner: requirements audit.
- [ ] CUS-002 — Implement Riverpod, GoRouter, secure refresh-token storage,
  single-flight refresh, restored guarded destinations, and connectivity state.
  Owner: customer frontend producer.
- [ ] CUS-003 — Implement production customer journeys for menu, builder, cart,
  fulfilment, checkout, orders, favorites, rewards, notifications, support, FAQ,
  account, privacy, and payment methods. Owner: customer frontend producer.
- [ ] CUS-004 — Reconcile customer API/OpenAPI/generated operations and fix the
  generated-package fixture lookup so tests are independent of Dart temporary
  kernel paths. Owner: backend/generated-contract producer.
- [ ] CUS-005 — Run customer Flutter, generated Dart, and focused backend
  deterministic checks; capture only the latest results. Owner: producers.
- [ ] CUS-006 — Complete the bounded private additive Stitch screen pass and
  independent design/accessibility review. Owner: root project coordinator.
- [ ] CUS-007 — Run independent code, design, accessibility, security, and safe
  Android-emulator QA gates; resolve P0/P1 findings within two revisions. Owner:
  independent reviewers and customer producer.
- [ ] CUS-008 — Reconcile the coverage audit and delivery report against final
  code/test evidence; record all provider/manual/release gates. Owner: project
  manager.

## Explicitly out of scope

- Production deployment or store publication.
- Credential, OAuth, payment-provider, mail, media, or push-provider activation.
- Editing, deleting, publishing, or sharing existing external design resources.
- Unrelated admin implementation changes.
