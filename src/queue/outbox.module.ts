import { Global, Module } from '@nestjs/common';
import { MailModule } from '../integrations/mail/mail.module';
import { OutboxService } from './outbox.service';
import { OutboxWorker } from './outbox.worker';

@Global()
@Module({
  imports: [MailModule],
  providers: [OutboxService, OutboxWorker],
  exports: [OutboxService, OutboxWorker],
})
export class OutboxModule {}
