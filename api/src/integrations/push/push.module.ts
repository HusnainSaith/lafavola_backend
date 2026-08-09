import { Global, Module } from '@nestjs/common';
import { FirebasePushProvider } from './firebase-push.provider';
import { PUSH_PROVIDER } from './push.interface';

@Global()
@Module({
  providers: [
    FirebasePushProvider,
    { provide: PUSH_PROVIDER, useExisting: FirebasePushProvider },
  ],
  exports: [PUSH_PROVIDER],
})
export class PushModule {}
