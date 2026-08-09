# La Favola public website

Astro static marketing and complete-menu site for the Brescia La Favola location. The website is intentionally non-transactional: it sends ordering intent to the pizzeria by telephone and contains no cart, account, checkout, payment, or order submission.

## Prerequisites

- Node.js `>=22.12.0` for the site package; the application workspace uses Node.js `>=24.14.0`.
- pnpm `10.32.1` (declared by the application workspace).
- Dependencies installed from `application/pnpm-lock.yaml`.
- `sharp` is a direct site dependency and is required for Astro to create responsive image variants.

No API key, database, backend, mobile SDK, or external service is required to run the public website locally.

## Install and run

From `application/`:

```powershell
corepack pnpm install --frozen-lockfile
corepack pnpm --filter @la-favola/site dev
```

Open `http://localhost:4321/`.

For a production-like local demonstration:

```powershell
corepack pnpm --filter @la-favola/site build
corepack pnpm --filter @la-favola/site preview --host 127.0.0.1
```

Astro prints the preview URL, normally `http://127.0.0.1:4321/`.

## Routes

- `/` — brand story, selected menu items, source photography, hours, location, and call actions.
- `/menu/` — complete supplied menu, variations, allergen notice, and original PDF download.
- `/informazioni/` — contacts, hours, delivery/payment details, allergens, privacy/legal readiness status, and accessibility contact.

## Validation

```powershell
corepack pnpm --filter @la-favola/site check
corepack pnpm --filter @la-favola/site build
corepack pnpm --filter @la-favola/site validate
```

The client-demo checklist and current production gates are in `docs/development/CLIENT_DEMO_RUNBOOK.md` from the project root.

## Content boundary

The site transcribes the supplied menu PDF and uses supplied brand/media files. Restaurant approval is still required before production publication for menu currentness, item-level allergen mapping, visible-person/image permissions, legal policies, domain/canonical host, and any analytics or cookie behavior.
