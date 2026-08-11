# La Favola Tablet Admin Design System

## Platform

Native Android tablet operations app. Design at 1280 × 800 landscape first,
with a resilient 1024 × 600 layout and a single-column portrait fallback.
Prioritise scanning, error prevention and fast one-handed/standing use.

## Brand tokens

- Espresso `#774E32`: primary app bar, navigation rail, primary button.
- Coffee `#6F4E37`: headings, links, focused fields and selected rows.
- Terracotta `#B7825F`: secondary actions and active operational emphasis.
- Dark terracotta `#925E3E`: destructive confirmation emphasis.
- Sand `#C0A891`, sand light `#F4EDE6`, paper `#FFFAF5`, ink `#3D2B20`:
  surfaces, dividers, content backgrounds and text.
- Poppins for UI and data; Lora only for page titles/short editorial moments.

## Shell and components

Warm paper main canvas, espresso navigation rail with icon plus label, top bar
with restaurant name, connection state, notification count and staff menu.
Use clear 8-point spacing, generous 12–16 dp corners, 48 dp minimum controls,
semantic status chips with icon plus text, data tables that can switch to cards,
sticky list filters, split-view details on landscape and bottom sheets on
narrow layouts.

## Accessibility and motion

WCAG AA contrast, explicit focus rings, labels never only placeholders, colour
never the sole status signal, Italian operational labels, scalable text,
keyboard navigation, and reduced-motion mode. Motion is 160–200 ms fade/slide
only for orientation; never delay order/status feedback.

## Canonical screens

1. Sign-in: restrained restaurant mark, email/password, clear validation,
   offline and expired-session states.
2. Dashboard: today’s operations, order/support/refund tiles, revenue summary,
   quick actions and attention queue.
3. Orders: filter rail, queue table, status chips, split order detail with
   guarded status controls, payment/refund history.
4. Menu editor: searchable catalogue, editing panel, price/ingredients/options,
   media slot, validation and unsaved-change warning.
5. Delivery dispatch: assignment panel, live-like status timeline, driver card,
   failure/retry message.
6. Support: queue, conversation detail, claim/status controls, composer.
7. Team and access: staff rows, role chips, permission review, self-lockout
   prevention warning.
8. Reports and settings: readable charts/tables, date filters, restaurant
   profile form and update confirmation.

Every screen must demonstrate normal, loading, empty, permission-denied and
API-error states where meaningful. Avoid dashboard wallpaper, gradients that
reduce data legibility, tiny tap targets, and generic blue SaaS styling.

## Private Stitch references

- Project: `projects/8916945245491125542` (private).
- Generated design system: `assets/c7d3c1e01ded48d7a048f00bb604679f`.
- Dashboard reference: `projects/8916945245491125542/screens/e37c097f18364cbda1fc16524e575d63`.
- Orders reference: `projects/8916945245491125542/screens/04bc82df20af4e42aedd468f179386c3`.
- Sign-in/session-recovery reference:
  `projects/8916945245491125542/screens/a4ab8c6771784c6799f9c3799b9f4fd3`.
- Catalogue reference:
  `projects/8916945245491125542/screens/b45ce284c1274eaebbefd8419b01eff9`.
- Support reference:
  `projects/8916945245491125542/screens/87f7045ad54844918deeec2d04937dbb`.
- Team, reports and settings reference:
  `projects/8916945245491125542/screens/181906c2c7264427907f11d14dcd1643`.

The outputs are visual references only. Flutter widgets use the documented
tokens and accessible native interaction behaviour; generated HTML is not
shipped.
