import { Module } from '@nestjs/common';
import { SupportController } from './support.controller';
import { SupportService } from './support.service';
import { SupportTicketRepository } from './repositories/support-ticket.repository';

@Module({
  controllers: [SupportController],
  providers: [SupportService, SupportTicketRepository],
  exports: [SupportService],
})
export class SupportModule {}
