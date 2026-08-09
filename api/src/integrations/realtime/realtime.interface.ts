export const REALTIME_PROVIDER = Symbol('REALTIME_PROVIDER');

export interface RealtimeEvent {
  id: string;
  type:
    | 'support.message.created'
    | 'support.ticket.assigned'
    | 'support.ticket.status_changed'
    | 'support.messages.read';
  ticketId: string;
  data: Record<string, unknown>;
  occurredAt: string;
}

export interface RealtimeMessagingProvider {
  publish(channel: string, event: RealtimeEvent): Promise<void>;
}
