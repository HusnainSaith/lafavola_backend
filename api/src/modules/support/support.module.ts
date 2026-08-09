import { Module } from '@nestjs/common';
import { SupportTicketRepository } from './repositories/support-ticket.repository';
import { SupportController } from './support.controller';
import { SupportService } from './support.service';
import { OutboxModule } from '../../queue/outbox.module';

@Module({
  imports: [OutboxModule],
  controllers: [SupportController],
  providers: [SupportService, SupportTicketRepository],
  exports: [SupportService],
})
export class SupportModule {}
