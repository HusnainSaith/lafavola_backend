# La Favola mobile

Flutter customer application for account, menu, pizza builder, checkout, and order tracking.
The normal `lib/main.dart` entrypoint uses `HttpWeek2Gateway`; deterministic data
exists only under `test/week2/support`.

## Customer order contract

- The customer chooses `delivery` or `pickup`; delivery requires an owned saved
  address, while pickup never sends or displays an address identifier.
- `/api/v1/restaurant/availability` is authoritative for Europe/Rome business
  hours, preparation lead time, ASAP eligibility, and readable 15-minute slots.
- Checkout revalidates opening hours and lead time. Delivery slots reserve both
  kitchen and transit time, and the configured closing instant is not orderable.
- Tracking uses the API `serverNow` value rather than the handset clock and
  renders ready/delivery estimates as a one-second countdown with polling
  recovery.
- Pizza-builder min/max, required groups, unavailable choices, incompatibilities,
  removals, and authoritative totals are enforced by the API. The UI prevents
  invalid submission and presents names instead of UUIDs.
- `/api/v1/orders/me/{id}/receipt` returns a readable non-fiscal order receipt.
  It is not represented as a legally fiscal invoice until an approved fiscal
  provider and restaurant data are configured.
- Active customer routes are localized in Italian (`it-IT`) and English (`en`).

## API configuration

Debug builds default to the Android emulator host `http://10.0.2.2:3001`. Override
it for a local device or integration environment:

```powershell
flutter run --dart-define=LA_FAVOLA_API_BASE_URL=http://10.0.2.2:3001
```

Release builds have no implicit endpoint and reject cleartext API URLs. Supply the
approved HTTPS origin at build time:

```powershell
flutter build apk --release --dart-define=LA_FAVOLA_API_BASE_URL=https://api.example.invalid
```

The example origin above is documentation-only and must be replaced by the
approved environment value. Android requests `INTERNET` in the main manifest;
cleartext traffic is enabled only by the debug manifest. Release signing is not
mapped to the debug key and must be supplied by the approved release environment.

Google and Apple buttons are absent unless their adapter and backend configuration
are both ready and the matching compile-time flag is set:

- `LA_FAVOLA_GOOGLE_AUTH_ENABLED=true`
- `LA_FAVOLA_APPLE_AUTH_ENABLED=true`

Do not enable a flag without the corresponding verified provider-return adapter.
Customer privacy actions exchange the current password for a short-lived proof
through the generated `customerReauthenticate` operation before sending an
export or deletion request.

## Validation

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

The complete widget suite uses some process-global test settings. Run it with
`flutter test --concurrency=1` for deterministic full-suite evidence.
