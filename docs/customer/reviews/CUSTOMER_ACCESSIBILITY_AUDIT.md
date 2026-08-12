# Customer accessibility audit

Status: **FINAL FAIL — revision 2 of 2 exhausted**  
Audit date: 2026-08-12  
Reviewer: independent accessibility reviewer; no producer code or design edited  
Release gate: zero unresolved P0/P1 findings

## Final verdict

| Scope | P0 | Open P1 | Verdict |
| --- | ---: | ---: | --- |
| 18 Stitch candidates | 0 | 7 | **FAIL / QUARANTINED** |
| Frozen Flutter implementation | 0 | 2 | **FAIL** |

The frozen Flutter implementation resolved three revision-1 defects: the active
home layout now reflows at 320 logical pixels with 200% text, the cash-order
primary action is explicitly 56dp high, and the splash implements an instant
reduced-motion path plus a labelled, focusable button surface.

The release gate still fails. The active `CustomerApp` and new modernization
routes lack the required route/state accessibility matrix, and static inspection
confirms remaining localized semantics, human-readable status, mutation-error
and destructive-action communication barriers. The candidate designs retain
seven P1 classes and cannot be revised within the exhausted 18-screen ceiling.
No conformance exception or risk acceptance is recorded.

## Scope, platforms and standard

This audit covers all 18 retrievable candidates in private OWNER Stitch project
`projects/15736357098573745733` using approved input asset
`assets/8453361971917840780`, plus frozen production entrypoint
`customer/lib/main.dart`, active routes in `customer/lib/app/customer_app.dart`
and their release-source widgets.

Supported acceptance contexts in scope are Android/mobile at 320 logical pixels
and normal phone widths, medium/expanded tablet widths, 200% text,
keyboard/focus, screen-reader-oriented Flutter semantics, relevant data and
failure states, and normal/reduced-motion parity. WCAG 2.2 Level AA principles
apply, especially SC 1.1.1, 1.3.1, 1.4.3, 1.4.4, 1.4.10, 1.4.11, 2.1.1,
2.1.2, 2.4.3, 2.4.6, 2.4.7, 2.4.11, 2.5.8, 3.1.2, 3.3.1–3.3.3, 4.1.2
and 4.1.3. The project contract is stricter than SC 2.5.8: every target is at
least 48dp and primary checkout/order tasks at least 56dp.

Excluded: producer edits, design generation/mutation, the public legacy Stitch
project, provider/production/device-farm actions, exception acceptance and
product accommodation choices. iOS VoiceOver conformance is not established.

## Revision-2 method and exact results

The producer declared the frozen customer implementation format/analyze clean,
180 tests passing and ten focused modernization tests passing. This reviewer
independently inspected the frozen source and reran the bounded tests below.
Automated/widget tests support the audit but do not prove native AT conformance.

### Modernization and active-route tests

```powershell
flutter test --no-pub test/modernization/customer_app_route_test.dart test/modernization/customer_feature_contract_test.dart test/modernization/customer_session_controller_test.dart
```

Result: exit 0, `+10: All tests passed!` (7.23 seconds reported by the command
runner). The tests comprise two active-route/guard tests, six feature API
contract tests and two session tests.

Focused active-route rerun:

```text
00:00 +0: guard preserves intended destination and provider return is public
00:00 +1: active home route reflows at 320px and 200 percent text
00:01 +2: All tests passed!
```

### Supporting release-source responsive/accessibility tests

```powershell
flutter test --no-pub test/week2/week2_responsive_accessibility_test.dart
```

Result: exit 0, `+15: All tests passed!` (16.37 seconds). It covers sign-in and
menu reflow at 320/768/1024/1440 with 200% text; semantics and 48dp actions;
failure-panel content; and eleven Week2 auth/account/menu source flows for
reflow, one Tab focus acquisition and action sizing at those widths.

### Manual evidence checks

- Flutter action primary/on-primary contrast is 5.31:1; secondary text/surface
  7.33:1; focus/surface 6.86:1; strong outline/surface 7.08:1.
- Candidate `outline-variant`/surface is 1.67:1 and approved
  `borderSubtle`/surface 1.59:1; neither may be the sole essential component
  boundary/state under SC 1.4.11.
- No active modernization test assertion exists for semantics trees, keyboard
  operation, 56dp checkout measurement, status announcements, localized
  semantic labels, splash semantics/focus or reduced-motion timing. The only
  active-page widget test pumps `CustomerHomePage` directly, not `CustomerApp`.
- Remaining Flutter examples below were checked directly in frozen source.

## Resolved Flutter findings

| Revision-1 finding | Revision-2 evidence | Status |
| --- | --- | --- |
| Home likely overflows at 320px/200% | `CustomerHomePage` uses one column for large text and fixed 112dp rows; the focused 320x700/2x test passes with no exception | **Resolved for tested home content** |
| Active checkout primary action lacks 56dp | `customer_feature_pages.dart:1215-1233` wraps the place-order button in `SizedBox(height: 56)` | **Code defect resolved; measurement belongs in F-A11Y-01** |
| Splash ignores reduced motion and is an unlabeled gesture | `week2_splash_screen.dart:34-42` advances after one frame when motion is disabled; lines 61-69 provide localized button semantics and focusable `InkWell` | **Code defect resolved; runtime regression belongs in F-A11Y-01** |

## Open Flutter findings

### F-A11Y-01 — P1 — Active release-route accessibility evidence is incomplete

References: all scoped WCAG criteria and modernization acceptance evidence.

Exact location/evidence:

- `customer/test/modernization/customer_app_route_test.dart:30-51` tests only
  `CustomerHomePage` at 320x700/200% with animations disabled and asserts text
  presence plus no exception.
- No modernization test pumps `CustomerApp`, traverses GoRouter routes, inspects
  semantics, sends keyboard input, measures checkout, observes an announcement,
  switches it/en, or instantiates splash, Cart, Checkout, Favorites, Rewards,
  Notifications, Support, FAQ, Payment Methods or Order Detail.
- The 15 passing Week2 tests support auth/account/menu source widgets but do not
  cover the new routes or router-level focus restoration.

Reproduction: search the modernization tests for `ensureSemantics`,
`sendKeyEvent`, `getSize`, `Week2SplashScreen`, `CheckoutRoutePage` and the new
page symbols; there are no relevant assertions. Run the recorded commands;
they pass while still omitting the required matrix.

User impact: a release route can regress name/role/state, keyboard order, focus
restoration, targets, 200% reflow, announcements or reduced motion while the
suite remains green.

Acceptance test: use deterministic success/failure/state fixtures to pump the
actual `CustomerApp` and traverse every release route at 320, phone, 768 and
1024 widths; 100%/200% text; it/en; and normal/disabled animations. Prove no
clipping/overflow; localized names/roles/states; logical visible keyboard focus,
modal containment/restoration and no trap; 48x48dp targets and 56dp order
action; all scoped data/error/destructive states; announcements; and splash
name, role, keyboard activation and instant reduced-motion advance. Supplement
with Android emulator external-keyboard and TalkBack-oriented manual smoke.

### F-A11Y-02 — P1 — Localized semantics and mutation/status/error communication remain incomplete

References: WCAG 2.2 SC 1.3.1, 3.1.2, 3.3.1–3.3.3, 4.1.2 and 4.1.3.

Exact location/evidence:

- `customer_feature_pages.dart:82-87` hard-codes semantic label `Loading` even
  for Italian.
- `customer_app.dart:141-144` hard-codes menu tooltip `Cart`; lines 187-190 use
  English `Support` as a cold/deep-link fallback.
- `customer_app.dart:329-335` and
  `customer_feature_pages.dart:1398-1418` expose raw server status, event
  type/nextStatus and occurrence time instead of localized user content.
- Favorites (`customer_feature_pages.dart:231-250`), notification mark-read
  (`394-400`), payment default/remove (`811-823`), cart line mutations
  (`898-951`) and reorder (`1431-1435`) await calls without route-local caught
  failure/retry or guaranteed accessible announcement. Favorites/payment/cart
  removal has no destructive confirmation.
- Checkout is a positive exception: lines 1242-1291 preserve retry, show
  localized success/failure and explicitly announce failure.

Reproduction: select Italian and inspect shared loading, Menu/Cart, a cold
Support route, Orders and Order Detail. With semantics enabled, force each
listed mutation to fail and perform removal. Observe English/internal content,
missing consistent success/error status, uncaught failure paths and removal
without confirmation.

User impact: users may hear the wrong language or internal enum, receive no
reliable mutation confirmation/recovery, or delete saved data accidentally.

Acceptance test: all visible/semantic copy comes from complete it/en
localization; enums/timestamps map to localized human content; every mutation
exposes localized busy/success/caught-error states, preserves retry and announces
non-focus changes without duplicate speech; destructive removals require a
named keyboard-operable confirmation and logical focus restoration; active
route tests prove both locales.

## Open Stitch-candidate findings

All 18 ledger IDs were retrieved in revision 1; candidate 7 uses full ID
`e7e4ec7f2efa499c95ffcc5fd5acaf7f`. The two DESIGN.md instances are excluded.
The candidate set remains quarantined with these P1 classes:

### C-A11Y-01 — P1 — Controls below 48dp/56dp

References: SC 2.5.8/project target. Home/Menu add/favorite, Item Detail
quantity/navigation and Cart edit/remove controls measure 24–40px. Impact:
touch-impaired users can miss or misactivate. Acceptance: every hit rectangle
48x48dp and primary order actions 56dp at all scales without overlap.

### C-A11Y-02 — P1 — Names, roles and states incomplete

References: SC 1.1.1, 1.3.1, 2.4.6, 4.1.2. Cart, Order Detail and Rewards have
unnamed controls; item context, selected tabs/nav and dialog states are
inconsistent. Impact: AT users cannot identify/predict controls. Acceptance:
localized contextual names, correct roles/values/states, alternatives and
dialog/tab/nav semantics.

### C-A11Y-03 — P1 — Keyboard focus behavior missing

References: SC 2.1.1, 2.1.2, 2.4.3, 2.4.7, 2.4.11. Most candidates rely on
hover/active styling and sheets/dialogs do not prove entry, containment,
Escape/back or restoration. Impact: users lose position or become trapped.
Acceptance: logical visible focus, full keyboard operation, no trap and modal
restoration.

### C-A11Y-04 — P1 — Zoom/reflow evidence invalid or absent

References: SC 1.4.4, 1.4.10. Several candidates disable zoom; the “320px”
resource reports 780px and Account Hub 1426px; fixed wrappers do not prove
200%/tablet reflow. Impact: enlarged content/actions can be clipped. Acceptance:
no zoom restriction and no lost content/focus/actions at 320px/200% or tablets.

### C-A11Y-05 — P1 — Validation/status announcements incomplete

References: SC 3.3.1–3.3.3, 4.1.3. Builder/cart/checkout/tracking/rewards/
notifications/support lack a complete live-status and associated-error model.
Impact: state/value changes are missed. Acceptance: associated errors,
first-invalid focus, localized announcements and non-color guidance.

### C-A11Y-06 — P1 — Reduced-motion parity absent

References: project motion acceptance and SC 2.2.2/2.3.3. Most candidates
animate without a complete fallback. Impact: vestibular discomfort or unequal
focus/timing. Acceptance: every specified transition becomes instant with
identical content, focus and status behavior.

### C-A11Y-07 — P1 — Boundary contrast and brand/content drift

References: SC 1.4.3, 1.4.11 and approved visual/content contract. Candidate
outline contrast is 1.67:1 if used as a sole essential boundary. Derived asset
`assets/aa037fbe9bf6429398437d397a3cc416` drifts to Noto Serif/generated colors;
menu, payment, reward and FAQ/ticket content is invented or English-only.
Impact: boundaries are missed and content can mislead. Acceptance: 3:1 essential
boundaries, compliant text/state cues, approved Lora/Poppins tokens and only
localized/server-authoritative content.

## Positive evidence that does not change the gate

- Frozen producer evidence reports format/analyze/full tests clean; this review
  reproduced the bounded 10-test, 2-test and 15-test results above.
- Theme text/focus/strong-boundary pairs pass manual contrast calculations.
- The theme supplies global 48dp targets and a visible 2px focus border;
  existing Week2 tests measure actions and basic Tab focus.
- Home reflow, checkout height and splash behavior are materially improved.
- Checkout provides a useful mutation-error/status implementation pattern.

## Limitations and exhausted gate

- No Android emulator accessibility tree, TalkBack, external keyboard, Switch
  Access, iOS VoiceOver, production API or device-farm check was performed or
  claimed in this pass.
- Candidate browser interaction remained blocked by the Windows ACL wrapper;
  revision-1 direct Stitch retrieval and HTML/screenshot metadata remain the
  candidate basis. Retrieval does not prove canvas placement or publication.
- Flutter semantics are not DOM ARIA; candidate HTML is design evidence only.
- Revision 2 is the maximum audit pass. The two Flutter and seven candidate P1
  classes must be resolved before release or escalated for an explicit human
  conformance exception/risk decision. The reviewer cannot accept that
  exception or choose a product accommodation.
