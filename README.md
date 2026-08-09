# La Favola

The main La Favola repository is organised as three sibling folders:

- `api/` — NestJS API, database migrations, tests, and backend tooling.
- `site/` — public Astro website deployed to `lafavolabrescia.it`.
- `branding/` — local brand source files and branding notes. Large original design files remain intentionally excluded from Git; deployable public assets live in `site/public/brand/`.

Run backend commands from `api/` and public-site commands from `site/`. Local environment files are ignored by Git and must never be committed.
