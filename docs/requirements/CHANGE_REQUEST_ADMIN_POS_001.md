# CR-ADMIN-POS-001: walk-in ordering and thermal receipt printing

Status: approved by the user on 2026-08-11

## Requested outcome

The La Favola administrator must create orders for customers physically present
at the restaurant, choose dine-in or takeaway, collect cash or external-terminal
card payment, and print or reprint a thermal receipt from the Android tablet.
La Favola remains a single-restaurant system.

## Accepted requirements

- Add a dedicated POS workspace; do not overload the customer checkout flow.
- Dine-in orders require a short table label. Takeaway orders do not.
- Customer name, phone and order notes are optional and snapshotted on the order.
- Menu, sizes, required option groups and choices come from an authenticated,
  restaurant-scoped POS catalogue.
- All prices, taxes and totals are recalculated by the API; the app never sends
  authoritative prices.
- Creating an order and collecting a payment are idempotent, recoverable steps.
- Cash and external card-terminal collection are supported. SumUp hosted customer
  checkout is not silently reused as an in-person terminal integration.
- Paid receipts can be retrieved and reprinted. Unpaid orders can print only an
  order ticket, not a payment receipt.
- Thermal output supports 58 mm and 80 mm ESC/POS layouts and Bluetooth, USB or
  network discovery where the Android hardware/driver permits it.
- Printer selection and paper width are local tablet settings; credentials and
  customer data are not written to application logs.
- Printed receipts carry `COPIA DI CORTESIA - NON FISCALE`. This feature does not
  claim Italian fiscal certification or replace a certified fiscal printer.

## Failure and recovery behavior

- A repeated create/collect request with the same idempotency key returns the
  original result; reuse with a different body is rejected.
- If payment collection fails after order creation, the order remains visible as
  unpaid and can be collected later without being duplicated.
- Printer absence, permission denial, disconnect and transport failure do not
  modify order/payment state; the receipt remains available for reprint.
- Cross-restaurant item/order/payment access is rejected even for administrators.

## Exclusions

Table reservations, seating maps, split bills, fiscal-device certification,
automatic cash-drawer control, kitchen display hardware and inventory depletion
are not implied by this request.

## Acceptance evidence

- Migration up/down and backend lint/unit/build pass.
- Real PostgreSQL HTTP flow creates dine-in and takeaway orders, prevents invalid
  table/type combinations, collects once, and retrieves/reprints the receipt.
- Flutter analysis/tests pass and Android integration covers POS navigation,
  cart editing, checkout recovery, receipt preview and printer-empty/error state.
- OpenAPI and admin coverage documentation contain every new route.
