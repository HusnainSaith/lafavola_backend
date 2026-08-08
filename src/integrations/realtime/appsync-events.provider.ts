import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RealtimeEvent, RealtimeMessagingProvider } from './realtime.interface';

@Injectable()
export class AppSyncEventsProvider implements RealtimeMessagingProvider {
  constructor(private readonly config: ConfigService) {}

  async publish(channel: string, event: RealtimeEvent): Promise<void> {
    if (!this.config.get<boolean>('AWS_REALTIME_ENABLED', false)) return;
    const controller = new AbortController();
    const timeout = setTimeout(
      () => controller.abort(),
      this.config.get<number>('AWS_REALTIME_TIMEOUT_MS', 5000),
    );
    try {
      const response = await fetch(
        `${this.config.getOrThrow<string>('AWS_APPSYNC_EVENTS_HTTP_URL').replace(/\/$/, '')}/event`,
        {
          method: 'POST',
          signal: controller.signal,
          headers: {
            'content-type': 'application/json',
            'x-api-key': this.config.getOrThrow<string>(
              'AWS_APPSYNC_EVENTS_API_KEY',
            ),
          },
          body: JSON.stringify({ channel, events: [JSON.stringify(event)] }),
        },
      );
      if (!response.ok) throw new Error('publish rejected');
    } catch {
      throw new ServiceUnavailableException(
        'Real-time delivery is unavailable',
      );
    } finally {
      clearTimeout(timeout);
    }
  }
}
