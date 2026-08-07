import { Injectable, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { SupportTicketRepository } from './repositories/support-ticket.repository';
import { SupportMessage } from './entities/support-message.entity';
import { CreateSupportTicketDto } from './dto/create-support-ticket.dto';
import { CreateSupportMessageDto } from './dto/create-support-message.dto';
import { UpdateSupportTicketDto } from './dto/update-support-ticket.dto';

@Injectable()
export class SupportService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly tickets: SupportTicketRepository,
  ) {}

  listCustomer(customerId: string) {
    return this.tickets.findMany({
      where: { customerId },
      order: { createdAt: 'DESC' },
    });
  }

  create(customerId: string, dto: CreateSupportTicketDto) {
    return this.tickets.save(
      this.tickets.create({
        ...dto,
        customerId,
        status: 'open',
        priority: dto.priority ?? 'normal',
      }),
    );
  }

  async detail(customerId: string, id: string) {
    const ticket = await this.tickets.findOne({ where: { id, customerId } });
    if (!ticket) throw new NotFoundException('Support ticket not found');
    const messages = await this.dataSource.getRepository(SupportMessage).find({
      where: { ticketId: ticket.id },
      order: { createdAt: 'ASC' },
    });
    return { ticket, messages };
  }

  async addCustomerMessage(
    customerId: string,
    ticketId: string,
    dto: CreateSupportMessageDto,
  ) {
    await this.detail(customerId, ticketId);
    return this.dataSource.getRepository(SupportMessage).save(
      this.dataSource.getRepository(SupportMessage).create({
        ticketId,
        authorUserId: customerId,
        authorType: 'customer',
        body: dto.body,
      }),
    );
  }

  listAdmin() {
    return this.tickets.findMany({ order: { createdAt: 'DESC' } });
  }

  async updateAdmin(id: string, dto: UpdateSupportTicketDto) {
    const ticket = await this.tickets.findById(id);
    if (!ticket) throw new NotFoundException('Support ticket not found');
    Object.assign(ticket, dto);
    if (dto.status === 'resolved') ticket.resolvedAt = new Date();
    if (dto.status === 'closed') ticket.closedAt = new Date();
    return this.tickets.save(ticket);
  }
}
