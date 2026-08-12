# Stitch customer screen ledger

Status: generated candidate evidence — 2026-08-12

## Safety boundary

- Private owner project: `projects/15736357098573745733`.
- Approved input design system: `assets/8453361971917840780`.
- The public legacy project `projects/410668225356694970` was not mutated.
- Work was additive only. No screen was edited or deleted and no project was
  published or shared.
- `list_screens` and `get_project` still expose only the two earlier
  `DESIGN.md` instances. Each generated resource below is retrievable through
  `get_screen`, but canvas placement is not confirmed. This is an integration
  visibility limitation, not evidence of publication or acceptance.

## Generated resources

| # | Screen ID | Candidate title |
| --- | --- | --- |
| 1 | `685f53eaaa134244a8c9ce1145c5c088` | Home — Discovery |
| 2 | `ba7dbaf1fec548d3bcb3a4457ed039f4` | Menu — Catalog |
| 3 | `ba763ee538a04a2988975a8a9c03d26d` | Item Detail — Selection |
| 4 | `2656599d26ee4b1e8d63c325124343e5` | Compact Stress Variant (320px) |
| 5 | `cd9ac3b8600c4e4fb7f900407077f1ce` | Pizza Builder |
| 6 | `563733e40fda4148bf8e2945884315dd` | Cart — Authoritative Quote |
| 7 | `e7e4ec7f2efa499c95ffcc5fd5acaf7f` | Checkout — Fulfillment & Payment |
| 8 | `cbf67bf994d74c89a48f5232213a62cd` | Review & Confirmation |
| 9 | `536a5e7003764ce49844769a1b4348b7` | Auth Entry — CUS-FLOW-03.1 |
| 10 | `3c9f5399ab594982a65fa702e648eafd` | Verification & Recovery |
| 11 | `17bb5c22d6814989bc5c960e3069fd83` | Order History — CUS-FLOW-03.3 |
| 12 | `f3d450d12a1546d4911f607529099939` | Order Detail — CUS-FLOW-03.4 |
| 13 | `73c232b82f3e4231bbd7d1fdd1181758` | Active Tracking — CUS-FLOW-03.5 |
| 14 | `4e23ce65e90640a0af1c6e0f35954be9` | Account Hub — CUS-FLOW-04.1 |
| 15 | `e7538dd9294842c5a02fdaf88f3de638` | Favorites — CUS-FLOW-04.2 |
| 16 | `2cb57017621a40f29c39eb5f34cf7848` | Rewards — CUS-FLOW-04.3 |
| 17 | `e36189bd0b5848c1aab84059d1a0f99c` | Notifications — CUS-FLOW-04.4 |
| 18 | `321fbac5fc164089a301d348376a9fd0` | Help & Support — CUS-FLOW-04.5 |

## Quarantined generation drift

Stitch also returned a derived asset `assets/aa037fbe9bf6429398437d397a3cc416`
whose internal theme substituted Noto Serif for Lora and changed some generated
Material colors. It is not approved for implementation. Some screens also
invented illustrative menu names, payment-mask examples, FAQ/ticket content,
and English status labels despite explicit placeholder constraints. Those
values are non-authoritative comparison material and must not enter runtime
copy or fixtures.

Flutter implementation remains governed by the exact approved Lora/Poppins
typography, semantic La Favola palette, server data, localization files, and
backend policy. Independent design and accessibility reviews gate whether any
candidate layout pattern is accepted.
