import { Global, Module } from '@nestjs/common';
import { AppSyncEventsProvider } from './appsync-events.provider';
import { REALTIME_PROVIDER } from './realtime.interface';

@Global()
@Module({
  providers: [
    AppSyncEventsProvider,
    { provide: REALTIME_PROVIDER, useExisting: AppSyncEventsProvider },
  ],
  exports: [REALTIME_PROVIDER],
})
export class RealtimeModule {}
