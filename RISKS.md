# La Favola risks

Updated: 2026-08-12

| ID | Risk | Impact | Mitigation / gate | Status |
| --- | --- | --- | --- | --- |
| R-001 | The customer app and generated package began as untracked work beside a large concurrent admin/API diff. | Accidental loss, overlap, or inflated completion claims. | Preserve all existing files, keep producer write scopes disjoint, and review only the frozen customer/customer-contract scope. | Active |
| R-002 | The former Stitch target is now public. | Private design material could be exposed or existing resources changed. | Do not mutate `projects/410668225356694970`; use only the preflighted private target under D-002 and additive limits. | Controlled |
| R-003 | Payment, OAuth, push, mail, media, signing, and production configuration require external accounts or credentials. | Some provider-backed paths cannot be release-verified locally. | Keep flags disabled, use truthful unavailable states, and require explicit provider/credential/production approval. | Active gate |
| R-004 | Broad UI coverage can hide route-only placeholders or weak failure-state behavior. | Planned journeys appear complete without usable API-backed flows. | Require feature-specific repository/controller behavior, loading/empty/error/offline/conflict states, deterministic tests, and independent QA. | Active |
| R-005 | Flutter widget tests do not by themselves prove Android runtime, visual, keyboard, screen-reader, or reduced-motion behavior. | Accessibility or responsive regressions may escape. | Use the connected Android 15 emulator plus independent design/accessibility/QA evidence; report assistive-technology limits. | Active |
| R-006 | Repository commands intermittently fail in the restricted Windows ACL wrapper. | Validation or documentation could be incomplete. | Use exact project-scoped approved commands, retain latest outputs, and never convert a tooling failure into a pass. | Active |
