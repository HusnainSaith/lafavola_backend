import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { SupportTicket } from '../entities/support-ticket.entity';

@Injectable()
export class SupportTicketRepository extends BaseRepository<SupportTicket> {
  constructor(dataSource: DataSource) {
    super(dataSource, SupportTicket);
  }
}
