# Admin app verification report

Date: 2026-08-11

## Passed evidence

- Backend Prettier, ESLint and Nest build passed.
- Backend unit suite: 84 passed; 42 provider/database-gated cases skipped by
  their explicit environment flags.
- Focused admin/security suite: 19 passed.
- OpenAPI regenerated successfully; route inventory contains 173 operations.
- Isolated PostgreSQL 15 cluster on loopback received all 23 migrations and
  the permission seed. No existing local or live database was used.
- Real HTTP run passed 14 authenticated queue/report/notification/audit reads
  and 35 temporary CRUD operations. Temporary records were deactivated or
  deleted through their public APIs.
- Flutter analyzer passed with no issues.
- Flutter unit/widget suite: 8 passed, including emulator text-field entry,
  auth refresh/error mapping and shell destination coverage.
- Native Android integration test on Android 15 / API 35: 1 passed. It signed
  in against the local API and opened all 13 admin destinations.
- Signed release APK assembled and signature-verified with Android APK
  Signature Scheme v1/v2. It targets API 35, supports API 23+, and has SHA-256
  `061A583D42238E4F6B76C9B26380C3043AEE44ACCD7D4790C77014F6BE00303C`.
- The live-configured release APK installed and launched successfully on the
  Android 15 / API 35 `emulator-5554` virtual device.
- Live read-only checks: health, Swagger UI and Swagger JSON each returned 200
  at `https://api.lafavolabrescia.it/api/v1`.

## Defects found and corrected during runtime verification

- Production scripts pointed to nonexistent `dist/main` and `dist/worker`.
- Joined TypeORM queue pagination used database column names where entity
  property paths were required.
- Support priority ordering generated an invalid SQL column reference.
- Notification `GET :id` shadowed `GET unread-count`.
- Notification device listing was missing.
- Report KPI cards overflowed at phone/portrait logical widths.
- Existing SumUp integration fixtures did not supply the newly required admin
  actor for scoped refund approval.

## External and deployment gates

- The live backend revision is ten operations behind the local verified
  contract; see `ADMIN_API_COVERAGE_MATRIX.md`. Production deployment was not
  performed in this implementation pass.
- S3 upload, SES delivery, SumUp refund/collection, AppSync realtime and FCM
  delivery require configured provider credentials and safe provider test
  accounts. They were not fabricated or exercised against production.
- A signed APK can be verified locally, but complete production behavior
  requires deploying the matching backend revision first.
