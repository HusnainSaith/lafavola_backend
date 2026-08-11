# Admin tablet release verification — 2026-08-10

## Release identity

- API release: `/var/www/lafavola-backend/releases/20260810-v1admin-r3`
- Public API base: `https://api.lafavolabrescia.it/api/v1/`
- Swagger: `https://api.lafavolabrescia.it/api/v1/docs`
- Android package: `com.lafavola.la_favola_admin`
- Android support: Android 6.0 / API 23 and later
- APK SHA-256: `856c51b6c81a2cbf9c8df4be66a9acee675e7c256f1f6b32ee892dd6a98b4dc2`
- Live APK download: `https://api.lafavolabrescia.it/downloads/la-favola-admin.apk`

## Verified results

| Scope | Result | Evidence |
| --- | --- | --- |
| Backend build and contract tests | Pass | ESLint, Nest build, and 7/7 targeted admin ownership tests passed. |
| Versioned production API | Pass | External HTTPS `health`, `ready`, and `docs-json` returned 200. |
| Swagger browser QA | Pass | Swagger rendered the `/api/v1` operations with no console errors. |
| CORS | Pass | `Origin: https://api.lafavolabrescia.it` received the matching allowed-origin and credentials headers. |
| Admin authorization seed | Pass | Production has 18 permissions and 18 admin-role assignments; the seed is idempotent. |
| Isolated CRUD QA | Pass | Login; restaurant/hours; users; staff; categories; ingredients; option groups/choices; promotions; coupons; FAQ; orders list/detail route; notifications; reports; and support queue were exercised against the dedicated QA database. Temporary QA records were removed. |
| Flutter validation | Pass | `flutter analyze` clean and 13/13 tests passing. |
| Signed APK | Pass | Release APK has one 4096-bit RSA signer and verified v1/v2 signatures. |
| Live APK publication | Pass | HTTPS download returned 200 with Android APK MIME type, attachment filename, expected byte length, and the exact signed-build SHA-256. |
| Emulator input | Pass | The installed release APK accepted both email and masked-password keyboard input. Screenshot: `admin/build/admin-live-release-inputs.png`. |

## Known verification boundary

The available Android emulator has no default network route, so it cannot reach the internet even though the app is installed and running. This is an emulator networking defect, not a tablet-app input or API defect: direct external HTTPS checks and the isolated end-to-end API suite passed. Validate live sign-in on a networked emulator or physical tablet before staff rollout.

The local backend runtime cannot start in this checkout because its local `.env` does not define `DB_HOST`. No local database configuration was invented or copied from production; use a dedicated local PostgreSQL configuration to complete an offline local-login test.

## Rollback

- Previous API release: `/var/www/lafavola-backend/releases/c91ed79`
- Pre-promotion PostgreSQL backup: `/var/backups/la-favola/lafavola_backend-before-v1admin-r3-20260810T132225Z.dump`
