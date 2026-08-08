# Live Chat Integration

## Selected transport

La Favola uses AWS AppSync Events as the managed real-time transport. PostgreSQL remains authoritative for tickets, messages, attachments and read state. AppSync broadcasts only committed outbox events.

AppSync Events provides managed HTTP publishing, WebSocket subscriptions, namespaces and subscribe-time handlers without a backend connection registry. API Gateway WebSockets would require connection-ID persistence and callback lifecycle management. A NestJS gateway would couple connection scaling to this API process. AppSync is usage-priced and removes connection-fleet operations.

Official references: [AppSync Events overview](https://docs.aws.amazon.com/appsync/latest/eventapi/event-api-welcome.html), [HTTP publishing](https://docs.aws.amazon.com/appsync/latest/eventapi/publish-http.html), and [event handlers](https://docs.aws.amazon.com/appsync/latest/eventapi/channel-namespace-handlers.html).

## Persistence and delivery

REST message creation authorizes the caller, validates the open conversation and finalized S3 attachments, persists the message, updates unread counters, and inserts `support.message.created` in one PostgreSQL transaction. The outbox worker publishes afterward with bounded retry. REST history remains complete during provider failures.

Events are `support.message.created`, `support.ticket.assigned`, `support.ticket.status_changed`, and `support.messages.read`. Conversation channels use `/support/{ticketId}`; agents also receive queue hints through `/support/queue`.

## Subscription authorization

The AppSync API must use a Lambda authorizer for client WebSocket authorization. API keys are backend publish-only and must never ship in a client. The authorizer validates the La Favola JWT and channel membership: customers must own the ticket; support follows queue/assignment policy; admins have oversight. `GET /support/tickets/:id/realtime-authorization` performs the backend membership check and returns the exact channel with a five-minute context. UUID knowledge alone is never sufficient.

## REST fallback and deployment

Create/list/detail, paginated history, send, mark-read, queue, claim and status update remain available over authenticated REST. Presence is not notification truth. Deployment requires an AppSync Event API/namespace, Lambda authorization, backend publish credentials, least-privilege policies, monitoring/WAF as appropriate, and the guarded provider smoke test.
