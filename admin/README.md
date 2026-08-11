# La Favola Admin

Production-oriented Flutter Material 3 console for La Favola's Android
restaurant tablet. La Favola is the only restaurant; the app has no tenant or
restaurant selector.

## Architecture

- feature-first workspaces under `lib/features`;
- Riverpod for session, connectivity and shared asynchronous server state;
- GoRouter authenticated shell;
- Dio API gateway with correlation IDs, safe idempotency, Italian error
mapping and one serialized refresh attempt;
- refresh token stored with Android Keystore-backed secure storage; access
  token kept in memory;
- a restaurant-scoped Cassa workspace for walk-in dine-in and takeaway orders,
  server-authoritative totals, cash/external-terminal collection and receipt
  reprinting;
- 58 mm and 80 mm ESC/POS printing over Android Bluetooth/BLE, USB or a saved
  network printer, with the printer configuration kept in secure storage;
- typed forms and guarded destructive actions, never raw JSON editors.

## Run locally

```powershell
flutter pub get
flutter run -d emulator-5554 `
  --dart-define=API_BASE_URL=http://10.0.2.2:3100/api/v1/
```

## Build for the live API

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://api.lafavolabrescia.it/api/v1/
```

Only the API URL belongs in a Dart define. Never compile AWS, database, mail,
payment, signing or administrator credentials into the app.

## Coverage

The shell exposes dashboard, orders/payment/refunds, delivery dispatch,
support, Cassa, catalogue/categories/ingredients/options/pizza rules, offers,
media, users/staff/RBAC, restaurant settings and hours, reports,
notifications/devices and audit activity. Customer-owned and provider webhook
routes are excluded.

Printed tickets are explicitly marked `COPIA DI CORTESIA - NON FISCALE`.
Physical-printer acceptance must still be performed on the client's exact
printer model and paper width; payment state never depends on printer success.

## Checks

```powershell
dart format lib test integration_test
flutter analyze
flutter test
flutter test integration_test/admin_app_e2e_test.dart -d emulator-5554 `
  --dart-define=API_BASE_URL=http://10.0.2.2:3100/api/v1/ `
  --dart-define=E2E_ADMIN_EMAIL=<local-test-email> `
  --dart-define=E2E_ADMIN_PASSWORD=<local-test-password> `
  --dart-define=E2E_POS_PRODUCT_NAME=<temporary-active-product>
```

The E2E values are runtime-only test inputs and must not be committed.
