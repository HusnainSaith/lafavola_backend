# La Favola

The main La Favola repository is organised as four sibling folders:

- `api/` — NestJS API, database migrations, tests, and backend tooling.
- `admin/` — signed Android Flutter tablet app for La Favola operations and
  walk-in POS.
- `site/` — public Astro website deployed to `lafavolabrescia.it`.
- `branding/` — local brand source files and branding notes. Large original design files remain intentionally excluded from Git; deployable public assets live in `site/public/brand/`.

Run backend commands from `api/` and public-site commands from `site/`. Local environment files are ignored by Git and must never be committed.

## API-only demo data

The admin test fixture copies the canonical categories and menu from
`site/src/data/menu.ts`. After a local or explicitly approved environment has
an active La Favola administrator and restaurant, run from `api/`:

```powershell
$env:SEED_API_BASE_URL='http://127.0.0.1:3001/api/v1'
$env:SEED_ADMIN_EMAIL='<admin-email>'
$env:SEED_ADMIN_PASSWORD='<runtime-secret>'
$env:SEED_DEMO_PASSWORD='<runtime-only-demo-password>'
$env:SEED_NAMESPACE='local-lafavola-demo'
npm run seed:admin-demo:api
```

The command authenticates normally and performs all menu/category, ingredient,
option, FAQ, promotion, coupon, driver, customer, POS, delivery and support
writes through HTTP endpoints. It is idempotent and contains no database
client. Media uploads and real refunds remain provider-gated by S3 and SumUp.
Never commit the runtime values.
