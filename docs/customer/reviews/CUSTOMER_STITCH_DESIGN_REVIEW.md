# Customer Stitch design review

Status: independent review, iteration 1 of 2  
Date: 2026-08-12  
Verdict: **REVISE — all candidates remain quarantined and non-authoritative**

## Review contract

This is one read-only review pass over the 18 additive customer-app candidates
in private OWNER project `projects/15736357098573745733`. The reviewed version
is the exact resource ledger in `docs/customer/STITCH_CUSTOMER_SCREEN_LEDGER.md`.
The public legacy project `projects/410668225356694970`, producer resources,
provider sharing/publication state, and Flutter implementation were not
modified.

Approved criteria:

- `DECISIONS.md` D-001 through D-003, especially server-authoritative content,
  the corrected private/additive Stitch boundary, and provider/release gates.
- `docs/customer/CUSTOMER_APP_MODERNIZATION_PLAN.md`: Information architecture,
  Journey and API coverage, State contract, Visual and interaction system,
  Motion, and Acceptance evidence.
- `customer/lib/design_system/tokens.dart` and
  `customer/lib/design_system/la_favola_theme.dart`: exact semantic palette and
  Lora/Poppins typography.
- `PROJECT_STATE.yaml`, `TASKS.md`, and `RISKS.md`, particularly R-003 through
  R-005.
- Approved input design-system asset `assets/8453361971917840780`, named by the
  contract as **Warm Editorial Craft**. The asset itself was not returned by the
  read-only design-system listing, so the checked-in exact Flutter tokens are
  the independently inspectable source for comparison.

Expected evidence covers compact, medium, and expanded layouts; 320px and
tablet rendering; 200% text; content and recovery states; touch/focus/semantic
behavior; normal and reduced motion; implementation feasibility; and asset and
content provenance.

Severity rules:

- **P0 — critical:** unsafe or destructive behavior, privacy/security exposure,
  or a defect invalidating the whole evidence set.
- **P1 — blocker:** violates an approved requirement or leaves evidence too
  incomplete to approve implementation adoption.
- **P2 — material:** should be corrected for production quality but does not by
  itself block the direction once all P1s are closed.
- **P3 — preference:** subjective refinement that does not alter acceptance.

Acceptance requires zero unresolved P0/P1 findings. Accepting a blocking
deviation, adopting the derived asset, or changing subjective direction
requires explicit human approval.

## Evidence inspected

- `get_project` confirmed title `La Favola Product UI`, `PRIVATE` visibility,
  `OWNER` role, and a mobile project. It exposed only the two pre-existing
  `DESIGN.md` instances.
- `list_screens` likewise returned only those two `DESIGN.md` instances.
- All 18 candidate IDs below were retrieved individually with `get_screen`.
  Each returned HTML and a screenshot resource. All 18 screenshots were
  rendered from the provider-returned bytes and visually inspected without
  saving or publishing provider assets.
- Returned HTML was inspected in memory for locale, effective theme values,
  typography configuration, control markup, motion declarations, reduced-motion
  markers, touch-size utilities, raw identifiers, and known invented values.
- `list_design_systems` for the project returned only derived
  `assets/aa037fbe9bf6429398437d397a3cc416`, not the approved asset. That derived
  asset is quarantined.
- Provider metadata dimensions are recorded as returned. They are not treated
  as logical Flutter dimensions. The compact candidate's HTML independently
  confirms `body { max-width: 320px; }`.

The browser-control connection was unavailable under the repository's known
Windows ACL wrapper. Direct in-memory rendering of the provider screenshot
bytes supplied the visual evidence; no local screenshot files were created.

## 18-screen evidence ledger

| # | Candidate | Provider evidence | Visual/state review | Disposition |
| --- | --- | --- | --- | --- |
| 1 | `685f53eaaa134244a8c9ce1145c5c088` — Home — Discovery | 780x1964, MOBILE; HTML + screenshot retrieved | Clear home hierarchy, restaurant status, active order, and popular items. Only content state is shown; menu names/prices/images are illustrative and non-authoritative. | Quarantine; revise under DR-01, DR-02, DR-04, DR-05. |
| 2 | `ba7dbaf1fec548d3bcb3a4457ed039f4` — Menu — Catalog | 780x1768, MOBILE; HTML + screenshot retrieved | Search, category/filter chips, product list, and sold-out treatment are legible. No loading/empty/error proof; compact chip targets are not proven 48dp. | Quarantine; revise under DR-01, DR-03 through DR-06. |
| 3 | `ba763ee538a04a2988975a8a9c03d26d` — Item Detail — Selection | 780x2082, MOBILE; HTML + screenshot retrieved | Strong product hierarchy and sticky quantity/add action. Product, size, availability, preparation-time, and price claims are invented examples; unavailable/conflict/validation states are absent. | Quarantine; revise under DR-01, DR-02, DR-04, DR-05. |
| 4 | `2656599d26ee4b1e8d63c325124343e5` — Compact Stress Variant (320px) | 780x2406, MOBILE; HTML + screenshot retrieved; HTML constrains body to 320px | Useful 320px visual, but its “200% text scaling” CSS block is empty. Category chips calculate to about 36px high and app-bar icon buttons have no 48px constraint. Line clamps hide menu text. | Quarantine; revise under DR-03, DR-05, DR-06. |
| 5 | `cd9ac3b8600c4e4fb7f900407077f1ce` — Pizza Builder | 780x2546, MOBILE; HTML + screenshot retrieved | Required choice, unavailable topping, incompatible-selection feedback, quantity, and total are visible. Missing loading, offline, refresh failure, min/max recovery, and stale-version/price-change evidence. | Quarantine; revise under DR-01, DR-02, DR-04, DR-05. |
| 6 | `563733e40fda4148bf8e2945884315dd` — Cart — Authoritative Quote | 780x1964, MOBILE; HTML + screenshot retrieved | Price-change and quote-expiry recovery are good concepts. Promo-code row visibly clips the Apply control at the right edge. No empty/offline/stale-version/destructive-confirmation evidence. | Quarantine; revise under DR-01, DR-03 through DR-06. |
| 7 | `e7e4ec7f2efa499c95ffcc5fd5acaf7f` — Checkout — Fulfillment & Payment | 780x1768, MOBILE; HTML + screenshot retrieved | Delivery/pickup, address, slot, disabled card-provider state, cash option, and order action are coherent. Missing address/slot/dependency/error states and reduced-motion proof. | Quarantine; revise under DR-01, DR-04, DR-05, DR-08. |
| 8 | `cbf67bf994d74c89a48f5232213a62cd` — Review & Confirmation | 780x2448, MOBILE; HTML + screenshot retrieved | Clear review hierarchy and non-fiscal disclaimer. `VISA •••• 4242`, delivery details, order items, and totals are invented data and cannot seed runtime UI or fixtures. | Quarantine; revise under DR-01 and DR-02. |
| 9 | `536a5e7003764ce49844769a1b4348b7` — Auth Entry | 780x1768, MOBILE; HTML + screenshot retrieved | Sign-in/register hierarchy is clear. English UI mixes an Italian email placeholder; Google/Apple actions lack provider-unavailable/loading/error variants and the HTML scan found no explicit ARIA attributes. | Quarantine; revise under DR-04, DR-05, DR-06, DR-07, DR-08. |
| 10 | `3c9f5399ab594982a65fa702e648eafd` — Verification & Recovery | 780x4428, MOBILE; HTML + screenshot retrieved | Good coverage of sent, invalid code, expired session, too-many-attempts, and temporary-service-error concepts, but they are stacked into one tall Italian sheet rather than handoff-ready state frames. It is the only Italian candidate. | Quarantine; revise under DR-03, DR-05, DR-07. |
| 11 | `17bb5c22d6814989bc5c960e3069fd83` — Order History | 780x1768, MOBILE; HTML + screenshot retrieved | Active/history navigation and active-order card are clear. No history content, loading, empty, offline-cached, reconnect, or failure view is evidenced. | Quarantine; revise under DR-04 through DR-07. |
| 12 | `f3d450d12a1546d4911f607529099939` — Order Detail | 780x3712, MOBILE; HTML + screenshot retrieved | Status, map, actions, items, totals, and non-fiscal copy are present. Dense secondary text is visually small; invented delivery/order data and live-map assumptions are not authoritative. | Quarantine; revise under DR-02, DR-03, DR-06, DR-08. |
| 13 | `73c232b82f3e4231bbd7d1fdd1181758` — Active Tracking | 780x2284, MOBILE; HTML + screenshot retrieved | Timeline hierarchy is strong. “Live tracking active,” courier location, and map content presume a configured provider; offline/reconnect and reduced-motion status-change evidence are absent. | Quarantine; revise under DR-04, DR-05, DR-08. |
| 14 | `4e23ce65e90640a0af1c6e0f35954be9` — Account Hub | 1426x2418, MOBILE; HTML + screenshot retrieved | Wider account grouping is useful and includes a refresh notice. It invents a person, email, postal address, sessions, and `VISA ending in 4242`; controls and secondary copy are excessively dense at the rendered scale. | Quarantine; revise under DR-02, DR-03, DR-06, DR-08. |
| 15 | `e7538dd9294842c5a02fdaf88f3de638` — Favorites | 780x2178, MOBILE; HTML + screenshot retrieved | Includes added/conflict/offline concepts. The `Offline — View Only` banner conflicts with enabled-looking filled “Add to Cart” controls. Foods, prices, and saved configurations are invented. | Quarantine; revise under DR-02 and DR-04; direct blocker DR-09. |
| 16 | `2cb57017621a40f29c39eb5f34cf7848` — Rewards | 780x4302, MOBILE; HTML + screenshot retrieved | Balance, redemption cards, insufficient-balance treatment, and history are broad. Points, tier, conversion, expiry, benefits, and reward eligibility invent restaurant loyalty policy. The tall composite is too dense for state handoff. | Quarantine; revise under DR-02 through DR-04 and DR-06. |
| 17 | `e36189bd0b5848c1aab84059d1a0f99c` — Notifications | 780x2046, MOBILE; HTML + screenshot retrieved | Push-disabled callout and inbox hierarchy are useful. Provider activation, notification bodies, and order/security claims must be conditional/server-driven; loading/empty/error/offline views are absent. | Quarantine; revise under DR-02, DR-04, DR-05, DR-08. |
| 18 | `321fbac5fc164089a301d348376a9fd0` — Help & Support | 780x3492, MOBILE; HTML + screenshot retrieved | FAQ, ticket list, and conversation structure are useful. FAQ/ticket IDs/status/messages/order details are invented and the very tall combined sheet is not a state-by-state handoff artifact. | Quarantine; revise under DR-02 through DR-05 and DR-07. |

## Blocking findings

### DR-01 — P1 — Approved theme is not faithfully applied

**Requirement references:** D-001; Modernization plan “Visual and interaction
system”; `tokens.dart`; `la_favola_theme.dart`; approved asset
`assets/8453361971917840780`.

**Evidence/location:** Every one of the 18 returned HTML candidates defines
effective `primary: #764628`, while the approved action primary is `#925E3E`.
The approved value appears as `primary-container`, which does not cure the role
swap. Twelve candidates also carry a `notoSerif` display token. Project metadata
and derived `assets/aa037fbe9bf6429398437d397a3cc416` identify Noto Serif as the headline font,
while the approved implementation limits Lora to expressive headings and uses
Poppins for controls/body.

**Impact:** Layout patterns cannot be copied safely: doing so would silently
change brand color roles and typography, breaking design-to-code traceability.

**Acceptance condition:** A future authorized generation pass must return HTML
and screenshots whose effective semantic roles exactly match the checked-in
tokens: action primary `#925E3E`, canvas `#FFFAF5`, surface `#FFFDF9`, ink
`#3D2B20`, coffee `#6F4E37`, and the remaining status/border roles; headings use
Lora and controls/body use Poppins. No Noto or `#764628` role may remain. The
derived asset stays quarantined and is not applied.

### DR-02 — P1 — Illustrative content is presented as product/account/policy data

**Requirement references:** D-001; Modernization objective; Journey/API
coverage; R-003 and R-004.

**Evidence/location:** Review and Account display `VISA ... 4242`; Account
invents a named person, email, address, and sessions; Favorites invents foods,
prices, and saved configurations; Rewards invents points, tier, benefits,
conversion, expiry, and redemption policy; Help invents tickets and messages.
Menu, item, order, tracking, and notification candidates similarly present
illustrative values as current server truth. Image URLs are generated
`aida-public` material with no project provenance record.

**Impact:** Adoption could leak fake PII/payment examples into fixtures, invent
restaurant and loyalty policy, conflict with authoritative server values, or
introduce unapproved image assets.

**Acceptance condition:** Candidate content must use explicit design-only
placeholders or a documented sanitized fixture set mapped to API fields. No real-
looking person, address, masked payment method, order/ticket reference, balance,
price, benefit, timing, status, or provider claim may be accepted as static
runtime copy. Production imagery must come from server-owned/provenanced assets
with documented fallbacks.

### DR-03 — P1 — Responsive and 200% text evidence is incomplete

**Requirement references:** Modernization “Visual and interaction system” and
“Acceptance evidence”; R-005.

**Evidence/location:** The set contains one confirmed 320px body and one wider
Account artifact, but not a coherent compact/medium/expanded family for the 18
destinations. The compact HTML's 200% text simulation block is empty. Cart clips
the Apply control on its promo-code row. Tall composite sheets (Verification,
Order Detail, Rewards, Help) do not prove reachable controls or reflow at 200%.

**Impact:** The design cannot be handed to Flutter with confidence at the
approved 600/1024 breakpoints or 320px/200% acceptance boundary.

**Acceptance condition:** Supply side-by-side evidence for representative high-
density journeys at 320px and 200% text, medium (600–1023), and expanded
(1024+) layouts. No horizontal clipping, line-clamped required content,
unreachable action, overlap, or order change may occur. Cart's promo action must
remain fully readable and operable.

### DR-04 — P1 — Required state coverage is not mapped or complete

**Requirement references:** Modernization “State contract” and every Journey/API
row; R-004.

**Evidence/location:** Useful isolated states exist (builder incompatibility,
cart price change/expiry, checkout provider unavailable, verification failures,
favorites offline/conflict, rewards insufficiency, push disabled). There is no
18-screen state matrix, and relevant surfaces lack representative loading,
refresh, empty, offline-cached/offline-unavailable, dependency unavailable,
unauthenticated, forbidden, not-found, stale/conflict, rate-limited, retryable
failure, in-flight-disabled, and destructive-confirmation evidence.

**Impact:** Happy-path screens can mask unusable API and recovery behavior and
cannot guide the production implementation required by the plan.

**Acceptance condition:** Add a traceable state matrix mapping every required
state to a shared component pattern and at least one inspected representative
screen. Each journey must identify which states apply, how mutation retry and
focus recovery work, and which server/API signal drives the state.

### DR-05 — P1 — Motion lacks reduced-motion parity evidence

**Requirement references:** Modernization “Motion” and “Acceptance evidence”;
R-005.

**Evidence/location:** All 18 HTML candidates contain transition declarations.
Fifteen contain no reduced-motion marker at all. The remaining three contain a
marker/comment but no rendered behavioral comparison. No normal/reduced-motion
video or state-sequence evidence was supplied.

**Impact:** Active scale/opacity/transform effects may remain enabled when
animations are disabled, and focus/content parity is unverified.

**Acceptance condition:** For each motion family, provide normal and
`disableAnimations`/reduced-motion evidence showing an instant alternative with
identical content, final state, focus, and operability. Remove or guard all
unnecessary transition and active-scale behavior.

### DR-06 — P1 — Visible touch-target and accessibility handoff gaps remain

**Requirement references:** Modernization 48dp/56dp targets, 200% text,
keyboard/focus, and screen-reader acceptance; R-005.

**Evidence/location:** Eleven candidate HTML files contain no explicit 48dp-like
size utility. In the 320px candidate, category chips use 14px text at 1.43 line
height plus 8px vertical padding, approximately 36px high; app-bar icon buttons
also have no 48px constraint. Several images are CSS background `div`s with a
custom `data-alt` attribute rather than native/semantic image alternative text.
Auth, Cart, Order Detail, and Rewards have sparse or zero explicit ARIA state
attributes. Account and several tall sheets render secondary copy at very small
visual sizes.

**Impact:** Touch, keyboard, screen-reader, and scaled-text accessibility cannot
be approved from this handoff; at least one compact control family visibly
violates the minimum target.

**Acceptance condition:** Demonstrate every interactive target at least 48x48
logical pixels (primary checkout/order actions 56px), including chips and icon
buttons; provide visible focus and logical focus order; expose selected,
expanded, disabled, current, error, live-status, and image alternatives through
semantic markup; and inspect at 200% text without truncating required content.

### DR-07 — P1 — Locale coverage is incoherent

**Requirement references:** Modernization “Acceptance evidence” requiring
Italian and English for every release route and semantic label.

**Evidence/location:** Seventeen candidates declare English; Verification &
Recovery alone declares Italian. Auth mixes English copy with an Italian email
placeholder. Several screens use fixed English operational/status strings.

**Impact:** The set is not a coherent single-locale flow and does not prove
either complete English or complete Italian coverage, including semantics and
long-text reflow.

**Acceptance condition:** Every visible and semantic string maps to an existing
localization key. Provide a route/state copy matrix for both Italian and English
and render representative longest-string screens in both locales at 200% text.

### DR-08 — P1 — Provider-gated behavior is sometimes represented as active

**Requirement references:** D-003; R-003; Modernization journey rows for
payment, notifications, tracking, and account.

**Evidence/location:** Checkout correctly shows card provider unavailable, but
Review/Account show a saved card, Tracking asserts live courier location/map,
Notifications offers push activation, and Account shows security sessions
without a consistent capability/state contract.

**Impact:** The designs can imply configured payment, location, push, or session
capabilities that remain external/manual gates and may not exist in the current
API/provider environment.

**Acceptance condition:** Each provider-backed control must be driven by a
documented capability flag/API state and include unavailable, permission-denied,
loading, retry, and safe fallback copy. No active card/location/push/session
claim appears without authoritative provider/server evidence.

### DR-09 — P1 — Favorites offline state contradicts its actions

**Requirement references:** Modernization “State contract” and Favorites
journey; R-004.

**Evidence/location/reproduction:** Open
`e7538dd9294842c5a02fdaf88f3de638`. The top banner says `Offline — View Only`,
while both favorite cards display filled, enabled-looking `Add to Cart` actions.

**Impact:** Users may attempt a mutation the state explicitly says is not
available, with no queued/retry semantics explained.

**Acceptance condition:** In offline view-only mode, mutation controls are
disabled with accessible reason text, or the design explicitly supports a
queued idempotent mutation and shows queued, retry, conflict, and cancellation
behavior.

### DR-10 — P1 — Candidate discoverability/canvas placement is unverified

**Requirement references:** D-002; `PROJECT_STATE.yaml` Stitch validators;
design-review evidence sufficiency.

**Evidence/location:** All 18 exact resources resolve with `get_screen`, but
`get_project.screenInstances` and `list_screens` expose only the two earlier
`DESIGN.md` instances. The producer ledger correctly records that candidate
canvas placement is not confirmed.

**Impact:** Individual resource existence is proven, but stable project-level
inventory, ordering, and review discoverability are not. The set cannot be
treated as a published or accepted board collection.

**Acceptance condition:** In a future explicitly authorized provider pass,
read-only project inventory must expose all 18 exact candidate IDs in the
private project, or the provider must supply an authoritative immutable
collection/manifest that can be independently reconciled one-to-one. No share
or publish action is implied.

## Non-blocking observations and preferences

- **P2 — Visual system strength:** The warm canvas, espresso/terracotta accents,
  editorial headings, restrained borders, and repeated bottom navigation form a
  coherent direction. Home, item detail, builder, checkout, review, and tracking
  show particularly clear hierarchy. Preserve these layout ideas while fixing
  the approved token roles.
- **P2 — Density:** Account, Rewards, Verification, Order Detail, and Help combine
  too many states/sections into very tall sheets. Split them into named state
  frames or provide a state gallery so production handoff and comparison are
  deterministic.
- **P2 — Navigation coherence:** Some transactional/detail screens appropriately
  omit bottom navigation, but the handoff should explicitly name modal/pushed
  versus shell destinations and expected back/deep-link behavior.
- **P3 — Image direction:** The food photography is appetizing but varies between
  rustic editorial, restaurant interior, and highly staged product imagery.
  Final selection should follow the existing server asset library and approved
  provenance rather than establish a new image direction in this review.

## Evidence gaps

- No interactive prototype behavior, keyboard traversal, screen-reader output,
  Android runtime, or Flutter implementation screenshot was part of this Stitch
  artifact review.
- No 200% rendered set, tablet/expanded set, focus set, motion video, or reduced-
  motion comparison was supplied.
- The approved Stitch asset could not be independently listed; only its durable
  ID and exact checked-in Flutter implementation tokens were available.
- Returned CSS/HTML can reveal implementation intent but does not prove logical
  Flutter size, runtime semantics, network behavior, or provider availability.
- Asset licensing/provenance was not supplied for generated screenshot imagery.

## Verdict and next gate

**REVISE.** There are no evidenced P0 findings, but DR-01 through DR-10 are open
P1 blockers. The 18 candidates are useful quarantined comparison material only;
neither the derived design-system asset nor invented content may enter Flutter,
fixtures, localization, or production assets.

The strict additive maximum of 18 screens has already been reached, so this
review does not authorize another provider generation or any edit/delete/share/
publish action. A future provider revision requires the root coordinator's
bounded authorization and, where it changes direction or accepts a deviation,
human approval. Independent design and accessibility re-review is required
after deterministic token/content/state/responsive/motion evidence is supplied.
