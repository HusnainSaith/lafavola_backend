# P1 EXTERNAL INTEGRATIONS — MAIL + S3 IMPLEMENTATION REPORT

## 1. Existing integration audit

The existing password-reset flow already generated cryptographically random tokens, persisted only SHA-256 digests and exposed a delivery boundary. The shared `verification_tokens` table supports email verification and was reused. Existing notification, outbox and media entities were also retained. The main gaps were empty outbox worker/service and S3 adapter implementations, no SMTP provider, no verification endpoints, and an upload flow with filename-derived keys and no ownership-aware finalization.

## 2. Mail architecture

Business code now targets the `MailProvider` injection token. `MailModule` supplies the Nodemailer adapter, while tests inject fakes. Authentication and outbox processing contain no Nodemailer imports.

## 3. Nodemailer implementation

`NodemailerMailProvider` builds its SMTP transport from validated configuration. It supports a disabled no-op mode for local/test environments, uses configured sender identity, supplies text and HTML alternatives, escapes template values, and maps provider failures to sanitized application errors without logging credentials, recipients or tokens.

## 4. Password-reset integration

The existing delivery boundary now builds a reset link from `PASSWORD_RESET_URL` and sends it through `MailProvider`. Only the digest is stored; the raw token appears only in the email link. The API never returns it. Provider errors are deliberately absorbed at the public forgot-password boundary so known and unknown addresses retain the same response during SMTP outages.

## 5. Email-verification implementation

Registration creates a one-hour `email_verify` token, stores its digest and sends the raw token through the configured verification link. `POST /auth/verify-email` locks and consumes a valid token once before setting `email_verified_at`. Authenticated `POST /auth/resend-verification` revokes older unused tokens and enforces a database-backed 60-second resend interval.

## 6. Transactional email events

Checkout enqueues `order.confirmed` inside the order transaction. Order status changes enqueue `order.status_changed` inside their transaction, covering ordinary updates including out-for-delivery and delivered. Account verification and password reset are direct security mail. Refund mail was evaluated but not added because the current refund workflow lacks a completed transactional state boundary suitable for this slice.

## 7. Outbox/retry implementation

`OutboxService` persists events using the caller's transaction manager. `OutboxWorker` claims due rows with PostgreSQL pessimistic locking and `SKIP LOCKED`, records attempts and sanitized failures, uses exponential backoff, marks success, and dead-letters after five attempts. Stable event IDs are sent as mail headers and published rows are not reclaimed. Delivery is at-least-once: a process crash after SMTP acceptance but before the published update can still duplicate an email. The worker is callable but a production scheduler or separate worker process must invoke it.

## 8. S3 architecture

`MediaService` targets a provider-neutral `StorageProvider`. `S3StorageProvider` uses modular AWS SDK v3 clients and supports the default credential chain/IAM roles; static credentials are optional.

## 9. Presigned-upload implementation

`POST /media/uploads` validates purpose, target, MIME and declared size before creating a five-minute, single-object PUT URL. Keys are generated from UUIDs on the server under restaurant menu, customer avatar or support-ticket prefixes. The supplied filename is metadata only and cannot override the key. `POST /media/:id/finalize` verifies S3 object size and MIME before activation.

## 10. Media security/ownership

Avatars are restricted to the authenticated customer, menu images to authorized administrators/active restaurant staff, and support attachments to the ticket customer or assigned staff. JPEG, PNG and WebP are allowed for images; PDF is additionally allowed only for support. Limits are 5 MB for images and 10 MB for support attachments. Deletion checks uploader ownership and deletes only the persisted trusted key. Public URLs are emitted only for menu assets through `AWS_S3_PUBLIC_BASE_URL`; avatar and support objects remain private.

## 11. New migration(s), if any

`1700000000018-AddMailAndMediaIntegrationMetadata` adds original filename, purpose and target metadata to `media_assets`, plus ownership/status and purpose/target indexes. It is forward-only; none of the prior 17 migrations was edited.

## 12. Environment variables added

Mail: `MAIL_ENABLED`, `MAIL_HOST`, `MAIL_PORT`, `MAIL_SECURE`, `MAIL_USER`, `MAIL_PASSWORD`, `MAIL_FROM_EMAIL`, `MAIL_FROM_NAME`, `PASSWORD_RESET_URL`, `EMAIL_VERIFICATION_URL`.

Storage: `AWS_S3_ENABLED`, `AWS_REGION`, `AWS_S3_BUCKET`, optional `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`, and `AWS_S3_PUBLIC_BASE_URL`.

Placeholders were added to `.env.example` and safe disabled values to `.env.test.example`; the real `.env` was not modified. Enabled providers fail validation when required configuration is missing. Static AWS keys are not required, preserving IAM-role deployment.

## 13. Swagger changes

Runtime DTO schemas and operation/response documentation cover verification, resend, forgot-password semantics, upload authorization, finalization and deletion. Provider objects, credentials and raw internal errors are not exposed.

## 14. Tests added

Coverage includes reset-link delivery and token-at-rest behavior, database-backed email verification and one-time use, environment validation, server-generated avatar keys, MIME/size rejection, five-minute presigning, finalization mismatch rejection and cross-user deletion rejection. Existing auth, migration, menu-query, promotion/concurrency, unit and E2E suites remain green.

## 15. Dependencies added/removed

Added `nodemailer`, `@aws-sdk/client-s3`, `@aws-sdk/s3-request-presigner`, and development typings `@types/nodemailer`. No duplicate mail package or AWS SDK v2 was introduced, and no unrelated package upgrade was performed. `npm` reports 34 pre-existing audit findings (3 low, 17 moderate, 14 high); no broad automatic upgrade was attempted.

## 16. Files changed

The material changes are under `src/integrations/mail`, `src/integrations/storage`, `src/integrations/aws/s3`, `src/queue`, and the auth, checkout, orders and media modules. Configuration validation, environment examples, migration registration/entity metadata, Swagger DTOs/controllers, tests, `package.json`, `package-lock.json`, and `REQUIREMENTS_TRACEABILITY.md` were updated. Unrelated pre-existing working-tree changes were preserved.

## 17. Known limitations

- Automated tests use provider fakes; no real Gmail or AWS account was contacted.
- The outbox processor requires deployment wiring to a recurring scheduler or independent worker.
- SMTP is inherently at-least-once around the final provider/database acknowledgement boundary.
- Finalization verifies S3-reported size and MIME metadata, not file magic bytes, malware or image decoding; production should add scanning/inspection before trusted publication.
- Menu reads assume a separately configured CloudFront/public read base. The bucket itself need not be public.
- Object deletion is immediate after authorization; lifecycle reconciliation should handle rare database/provider partial failures.

## 18. Remaining integration work

Configure and smoke-test production SMTP and AWS IAM/bucket/CORS/read-layer policies; deploy the outbox runner and monitoring; add content scanning and reconciliation; and expand database-backed menu/support media authorization matrices. SumUp, live chat and push notification providers remain intentionally untouched.

## Exact validation results

- `npm run format`: PASS
- `npm run lint:check`: PASS
- `npm run build`: PASS
- `npm test -- --runInBand`: PASS — 7 suites, 49 tests passed; 3 opt-in database suites skipped by the default command
- `npm run test:e2e -- --runInBand`: PASS — 1 suite, 2 tests
- PostgreSQL integration tests: PASS — migration/auth 11 tests and P1 ordering/concurrency 7 tests
- Fresh migrations: PASS — all 18 migrations applied to guarded `lafavola_test`; second migration run was a no-op

This report covers only the mail and S3 integration slice and does not claim that the whole backend is production-ready.
