# P1 LIVE CHAT + PUSH IMPLEMENTATION REPORT

## 1. Existing support/notification audit

The ticket/message/attachment and notification/preference/device/delivery schemas were reusable. Gaps were CRUD-only chat, unbounded history, missing staff replies/claims/read state, no durable realtime delivery, token lifecycle gaps, empty Firebase code and no push outbox handler.

## 2. AWS real-time options evaluated

AppSync Events offers managed pub/sub, namespaces and subscribe handlers. API Gateway WebSockets require connection storage/callback lifecycle. A Nest gateway requires distributed connection infrastructure when scaled. PostgreSQL remains authoritative in every option.

## 3. Selected AWS transport and reason

AWS AppSync Events was selected for managed scaling and native HTTP-publish/WebSocket-subscribe behavior. Details are in `LIVE_CHAT_INTEGRATION.md`.

## 4. Live-chat architecture

`SupportService -> transactional outbox -> RealtimeMessagingProvider -> AppSyncEventsProvider`. Disabled providers retain REST/persistence behavior.

## 5. PostgreSQL persistence model

Existing tickets/messages/attachments are retained. Migration 20 adds last-message, assignment, side-specific last-read timestamps and unread counters. Message/outbox insertion is atomic.

## 6. Channel authorization

Private `/support/{ticketId}` channels require JWT ownership or role/assignment access through an AppSync Lambda authorizer. The backend exposes a short-lived channel authorization context. The publish API key is backend-only.

## 7. Support assignment behavior

Queue filtering/pagination/sorting is database-side. Claim locks the ticket; simultaneous claims have exactly one winner. Support agents write only assigned conversations; admins retain oversight.

## 8. Read/unread implementation

Side-specific counters/timestamps avoid a read row per message. Messages increment the opposite side; mark-read atomically resets the caller's side and emits a realtime event.

## 9. Outbox/retry behavior

Realtime and push reuse the five-attempt `SKIP LOCKED` worker and exponential backoff. Stable event IDs and database uniqueness protect retries.

## 10. Push architecture

The worker persists in-app notifications, evaluates preferences, creates per-device deliveries and calls `PushNotificationProvider`; push is never the source of truth.

## 11. Firebase implementation

`FirebasePushProvider` uses official `firebase-admin`, service-account fields, escaped multiline key handling, normalized results and sanitized errors. Invalid/unregistered tokens are permanent failures.

## 12. Device-token behavior

Tokens derive user identity from JWT, remain globally unique, cannot be silently transferred, can be owner-deactivated, and are retired on permanent FCM errors. iOS/Android and the existing optional web enum remain supported.

## 13. Notification preferences

Order pushes respect `push_order_updates`; marketing infrastructure uses `push_promotions`; coupon expiry retains its dedicated flag. Support replies are transactional, not marketing.

## 14. Notification idempotency

Unique `(user_id,event_key)` notifications and per-notification/device deliveries prevent replay duplication.

## 15. Migration 20

`1700000000020-AddLiveChatAndPushIntegrity` adds chat read/assignment/queue fields and indexes plus notification/delivery uniqueness. Migrations 1–19 are unchanged.

## 16. Environment variables

AppSync: `AWS_REALTIME_ENABLED`, `AWS_APPSYNC_EVENTS_HTTP_URL`, `AWS_APPSYNC_EVENTS_WS_URL`, `AWS_APPSYNC_EVENTS_API_KEY`, `AWS_REALTIME_TIMEOUT_MS`, `RUN_AWS_REALTIME_TESTS`. Firebase: `PUSH_ENABLED`, `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`, `RUN_FIREBASE_TESTS`. Real `.env` was untouched.

## 17. Swagger/documentation changes

REST chat/queue/history/read/claim/channel authorization and device lifecycle routes are documented. Realtime transport is documented separately in `LIVE_CHAT_INTEGRATION.md`.

## 18. Tests added

Tests cover AppSync payload/failure handling, message/outbox persistence, unread/read, closed-message rejection, claim concurrency, support notification persistence and invalid-token retirement.

## 19. Dependencies added/removed

Added official `firebase-admin`. No redundant WebSocket/AWS/push library was added. npm reports 39 audit findings; unrelated breaking upgrades were not attempted.

## 20. Files changed

Material changes are under realtime/push integrations, support/notifications, outbox worker, migration 20, configuration/examples, tests, package manifests and documentation.

## 21. Known limitations

- Real AWS/Firebase services were not contacted without credentials.
- AppSync namespace/Lambda authorizer and a recurring outbox worker must be deployed separately.
- Driver-arriving needs a future explicit proximity event; it is not inferred from noisy GPS.
- Promotion/coupon campaign scheduling remains deployment-scheduled and is never auto-blasted.
- Presence is intentionally not persisted or required for push correctness.

## 22. Remaining deployment work

Deploy AppSync/Lambda authorization, configure Firebase/mobile apps, deploy and monitor the worker, run real-provider smoke tests, and configure targeted campaign schedules.

## Validation

- Prettier check, ESLint check and Nest build: passed.
- Default unit/regression suite: 9 suites and 58 tests passed; 5 credential/database-gated suites (25 tests) skipped by design.
- HTTP e2e suite: 2 tests passed.
- Fresh migration/authentication PostgreSQL suites: 11 tests passed, including all 20 migrations and the no-op second run.
- Ordering PostgreSQL suite: 7 tests passed.
- SumUp payment/refund PostgreSQL suite: 3 tests passed.
- Live-chat/push PostgreSQL suite: 4 tests passed, including concurrent claim and invalid-token retirement.
- Real AWS AppSync and Firebase smoke tests: SKIPPED because credentials and provisioned provider resources were not supplied.

This validates this implementation slice; it does not declare the entire backend production-ready.
