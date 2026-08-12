# Customer Android emulator QA

Status: **REJECT / BLOCKED** — pass 1 of 2, 2026-08-12

## Verdict

The frozen debug APK installs and renders on the authorized Android 15 emulator.
The unauthenticated guard and public API-unavailable states are usable, and no
process crash was captured. The release gate is not accepted because one
implementation P1 localization defect is reproducible in public routes and the
bounded run did not cover authenticated restoration, 320px/tablet, 200% text,
rotation, or reduced-motion behavior.

- P0: 0 confirmed.
- P1: 1 confirmed (`CUST-EMU-001`).
- Crash/ANR: no crash was present in the crash buffer and no filtered
  `AndroidRuntime`, `ActivityManager`, or `flutter` error was returned during the
  recorded flows. An exhaustive ANR/performance profile was not run.
- Backend E2E: **not tested**. No local API or safe account was supplied.
- Production/provider behavior: **not tested**. No production, provider,
  credential, customer-data, payment, submission, notification, or mutation
  action was performed.

## Acceptance basis and boundary

Inputs read before execution:

- `PROJECT.md`, `PROJECT_STATE.yaml`, `TASKS.md`, `DECISIONS.md`, `RISKS.md`
- `docs/customer/CUSTOMER_APP_MODERNIZATION_PLAN.md`
- `docs/customer/CUSTOMER_FEATURE_COVERAGE_AUDIT.md`
- `docs/customer/reviews/CUSTOMER_ACCESSIBILITY_AUDIT.md`
- `docs/customer/reviews/CUSTOMER_STITCH_DESIGN_REVIEW.md`
- `customer/README.md`, current router/entrypoint, and Android configuration

The modernization acceptance relevant to this run requires public browsing,
guarded destination restoration, Italian and English on all release routes,
responsive behavior at 320px/tablet/200% text, and normal/reduced-motion parity.
The test environment was the explicitly authorized `emulator-5554`. The debug
app defaults to `http://10.0.2.2:3000`; that API was unavailable, so only safe
failure behavior was exercised. No mock gateway was substituted: the production
entrypoint uses the HTTP-backed providers. Authenticated and mutation flows were
not called.

## Device, APK, and installed application identity

| Item | Observed value |
| --- | --- |
| Device serial | `emulator-5554` |
| Product/model | `sdk_gphone64_x86_64` |
| OS/API | Android 15 / API 35 |
| Display | 1080x1920 px, 420 dpi; Android reported 411x731 dp app configuration |
| APK | `customer/build/app/outputs/flutter-apk/app-debug.apk` |
| APK size | 198,642,470 bytes |
| APK modified UTC | 2026-08-12 03:31:34Z |
| APK SHA-256 | `777D21367E69ECA0863C27DF7D3C25C673F981496EE9A24B50C556E2CA34C1D6` |
| Package/activity | `it.lafavola.customer/.MainActivity` |
| Installed version | `1.1.5` (`versionCode=7`) |
| ABI/build | x86_64, debuggable, APK signing v2 |
| SDK bounds | `minSdk=23`, `targetSdk=35`; source build config uses `compileSdk=36`, NDK 27 |

Install result:

```text
Performing Streamed Install
Success
```

## Executed flow matrix

| ID | Flow / expected result | Actual result | Status | Evidence |
| --- | --- | --- | --- | --- |
| EMU-01 | Install exact debug APK | `adb install -r -t` returned `Success`; package identity matched | PASS | package dump in command transcript |
| EMU-02 | Cold launch without crash | First `am start -W` returned `Status: timeout`, `WaitTime: 11205`, but PID `5415` was live and Android reported the activity `RESUMED`, visible and `reportedDrawn=true`. Two explicit cold deep-link launches later returned `ok` in 5.582s and 6.256s | PASS with performance observation | `01_boot.*`, activity dump |
| EMU-03 | Safe unauthenticated landing | Rendered Italian sign-in with sign-in, recovery, guest, registration, and verification actions | PASS | `01_boot.png`, `01_boot.xml` |
| EMU-04 | Public menu without account | Guest action reached the public menu. At 10s it showed `Loading...`; at about 30s it changed to a readable timeout panel with an enabled `Retry` button | PASS for unavailable-state rendering; retry request not re-fired | `02_guest_menu.*`, `03_guest_menu_after_30s.*` |
| EMU-05 | Guarded `/favorites` deep link while signed out | Explicit VIEW intent to `/favorites` cold-launched successfully and rendered sign-in, not favorite content | PASS for guard; post-login restoration unverified | `04_guarded_favorites.*` |
| EMU-06 | Public `/faq` deep link while signed out | Explicit VIEW intent opened FAQ without authentication and rendered a timeout/retry state | PASS for route/availability; FAIL localization | `05_public_faq.*` |
| EMU-07 | API unavailable recovery safety | Menu and FAQ timed out without crash, exposed retry, and did not display raw identifiers or stack traces | PASS for displayed state | `03_guest_menu_after_30s.xml`, `05_public_faq.xml` |
| EMU-08 | Crash/error inspection | Crash buffer and focused `AndroidRuntime:E ActivityManager:E flutter:E` captures returned no entries during the recorded runs | PASS within focused capture | command transcript |
| EMU-09 | Guard matrix beyond favorites (`cart`, `checkout`, `orders`, account, payments, support) | Static router places them behind the same guard, but they were not each runtime-launched | NOT RUN | coverage gap |
| EMU-10 | Authenticated destination restoration and business journeys | No safe account/API was available; no login, cart mutation, checkout, order, favorite, reward, support, privacy, payment, or notification mutation was attempted | BLOCKED | environment boundary |
| EMU-11 | Responsive/compatibility | Portrait compact runtime only (411x731 dp). No 320px, landscape, medium/tablet, expanded, split screen, 200% text, or keyboard run | NOT RUN | coverage gap |
| EMU-12 | Reduced motion | No Android animation-scale/reduced-motion comparison was completed before the coordinator requested finalization | NOT RUN | coverage gap |

## Defect

### CUST-EMU-001 — P1 — Default Italian locale mixes English on public routes

Requirement: modernization acceptance requires Italian and English coverage for
all release routes and semantic labels.

Reproduction:

1. Install and cold-launch the debug APK with no authenticated session.
2. Observe the Italian sign-in (`Accedi`, `Continua come ospite`).
3. Tap `Continua come ospite` and wait for the unavailable API timeout.
4. Observe English menu content: `Public menu`, `We could not load the live
   menu`, and `The request timed out. Please try again.`
5. Cold-launch the explicit public `/faq` deep link and wait for timeout.
6. Observe Italian `Domande frequenti` and `Riprova` surrounding English `The
   request timed out. Try again safely.`

Expected: with the default `it-IT` locale, all visible and semantic public-route
copy is Italian; switching to English should produce a consistently English
route.

Actual: the same runtime route mixes Italian and English.

Impact: a release-route localization acceptance criterion fails in the primary
unauthenticated/API-unavailable journey. This blocks emulator QA acceptance.

Evidence:

- `01_boot.xml`
- `03_guest_menu_after_30s.xml`
- `05_public_faq.xml`

Required verification after fix: repeat EMU-03, EMU-04, and EMU-06 in both
`it-IT` and `en`, including loading, timeout, retry, empty, and route labels.
This report is pass 1; at most one QA revision remains under the assigned
two-pass contract.

## Non-blocking observations

- The first direct launcher measurement timed out after 11.205s even though the
  app subsequently reported drawn. Explicit cold VIEW launches completed in
  5.582s and 6.256s. Because this is a large debug APK on an emulator and no
  startup threshold was approved, this is recorded as a performance observation,
  not a release-severity defect.
- Several UI-automator nodes, including sign-in fields/icon actions and the
  public-menu app-bar action, were emitted as `NAF=true` with empty content
  descriptions. UI Automator alone is insufficient to assign a new severity;
  reconcile this evidence with the separate accessibility audit and a TalkBack
  pass before accessibility acceptance.
- The Android manifest exposes only the launcher filter. The tested deep links
  used explicit component intents, which verifies GoRouter handling inside the
  app but does not prove OS-level verified/app-link discovery from another app.

## Coverage and release gaps

The following remain required before claiming the broader emulator acceptance:

- fix and re-run `CUST-EMU-001` in Italian and English;
- authenticated guard restoration to the original `from` destination using an
  approved local test account/API;
- menu success/empty/search/detail/builder and authenticated cart-through-order
  business flows against a safe local API;
- actual retry execution and offline-to-online reconnection;
- 320px, medium/tablet, expanded/landscape, split-screen, and 200% text;
- normal versus `MediaQuery.disableAnimations`/reduced-motion parity;
- keyboard/focus and TalkBack behavior;
- provider-backed paths only after their separate human/provider approvals.

## Exact commands and results

ADB executable used because `adb` was not on `PATH`:

```powershell
$adbExe = 'C:\Users\artte\AppData\Local\Android\Sdk\platform-tools\adb.exe'
```

Identity and install:

```powershell
& $adbExe devices -l
& $adbExe -s emulator-5554 shell getprop ro.product.model
& $adbExe -s emulator-5554 shell getprop ro.build.version.release
& $adbExe -s emulator-5554 shell getprop ro.build.version.sdk
& $adbExe -s emulator-5554 shell wm size
& $adbExe -s emulator-5554 shell wm density
& $adbExe -s emulator-5554 install -r -t 'D:\work\Live-Projects\lafavola_backend\customer\build\app\outputs\flutter-apk\app-debug.apk'
& $adbExe -s emulator-5554 shell dumpsys package it.lafavola.customer
```

Launch and evidence pattern:

```powershell
& $adbExe -s emulator-5554 logcat -c
& $adbExe -s emulator-5554 shell am force-stop it.lafavola.customer
& $adbExe -s emulator-5554 shell am start -W -n it.lafavola.customer/.MainActivity
& $adbExe -s emulator-5554 shell screencap -p /sdcard/lafavola_boot.png
& $adbExe -s emulator-5554 pull /sdcard/lafavola_boot.png docs/customer/qa/evidence/01_boot.png
& $adbExe -s emulator-5554 shell uiautomator dump /sdcard/lafavola_boot.xml
& $adbExe -s emulator-5554 pull /sdcard/lafavola_boot.xml docs/customer/qa/evidence/01_boot.xml
& $adbExe -s emulator-5554 logcat -d -b crash
& $adbExe -s emulator-5554 logcat -d -v time 'AndroidRuntime:E' 'ActivityManager:E' 'flutter:E' '*:S'
```

Safe route launches:

```powershell
& $adbExe -s emulator-5554 shell am start -W -a android.intent.action.VIEW -d https://lafavola.invalid/favorites -n it.lafavola.customer/.MainActivity
& $adbExe -s emulator-5554 shell am start -W -a android.intent.action.VIEW -d https://lafavola.invalid/faq -n it.lafavola.customer/.MainActivity
```

The favorites launch returned `Status: ok`, `LaunchState: COLD`,
`TotalTime: 5582`, `WaitTime: 5628`. The FAQ launch returned `Status: ok`,
`LaunchState: COLD`, `TotalTime: 6256`, `WaitTime: 6346`.

## Evidence inventory

- `docs/customer/qa/evidence/01_boot.png` and `.xml`
- `docs/customer/qa/evidence/02_guest_menu.png` and `.xml`
- `docs/customer/qa/evidence/03_guest_menu_after_30s.png` and `.xml`
- `docs/customer/qa/evidence/04_guarded_favorites.png` and `.xml`
- `docs/customer/qa/evidence/05_public_faq.png` and `.xml`

