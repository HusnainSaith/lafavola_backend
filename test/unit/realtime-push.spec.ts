import { ConfigService } from '@nestjs/config';
import { ServiceUnavailableException } from '@nestjs/common';
import { AppSyncEventsProvider } from '../../src/integrations/realtime/appsync-events.provider';

describe('AppSync Events provider', () => {
  const values: Record<string, unknown> = {
    AWS_REALTIME_ENABLED: true,
    AWS_APPSYNC_EVENTS_HTTP_URL: 'https://events.example.com',
    AWS_APPSYNC_EVENTS_API_KEY: 'backend-secret',
    AWS_REALTIME_TIMEOUT_MS: 1000,
  };
  const config = {
    get: jest.fn((key: string, fallback?: unknown) => values[key] ?? fallback),
    getOrThrow: jest.fn((key: string) => values[key]),
  } as unknown as ConfigService;
  afterEach(() => jest.restoreAllMocks());

  it('publishes a safe stringified event to one private conversation channel', async () => {
    const fetchMock = jest
      .spyOn(global, 'fetch')
      .mockResolvedValue({ ok: true } as Response);
    await new AppSyncEventsProvider(config).publish('/support/ticket-1', {
      id: 'event-1',
      type: 'support.message.created',
      ticketId: 'ticket-1',
      data: { messageId: 'message-1', body: 'hello' },
      occurredAt: new Date(0).toISOString(),
    });
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe('https://events.example.com/event');
    expect(init?.headers).toEqual(
      expect.objectContaining({ 'x-api-key': 'backend-secret' }),
    );
    const body = JSON.parse(String(init?.body));
    expect(body.channel).toBe('/support/ticket-1');
    expect(JSON.parse(body.events[0])).not.toHaveProperty('customerEmail');
  });

  it('sanitizes provider failure for outbox retry', async () => {
    jest.spyOn(global, 'fetch').mockRejectedValue(new Error('AWS internals'));
    await expect(
      new AppSyncEventsProvider(config).publish('/support/ticket-1', {
        id: 'event-1',
        type: 'support.message.created',
        ticketId: 'ticket-1',
        data: {},
        occurredAt: new Date().toISOString(),
      }),
    ).rejects.toThrow(ServiceUnavailableException);
  });
});
