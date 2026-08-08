import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { OutboxService } from '../../queue/outbox.service';
import { MediaAsset } from '../media/entities/media-asset.entity';
import { Order } from '../orders/entities/order.entity';
import { CreateSupportMessageDto } from './dto/create-support-message.dto';
import { CreateSupportTicketDto } from './dto/create-support-ticket.dto';
import { SupportMessageAttachment } from './entities/support-message-attachment.entity';
import { SupportMessage } from './entities/support-message.entity';
import { SupportTicket } from './entities/support-ticket.entity';
import { SupportTicketRepository } from './repositories/support-ticket.repository';

@Injectable()
export class SupportService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly tickets: SupportTicketRepository,
    private readonly outbox: OutboxService,
  ) {}

  listCustomer(customerId: string, page = 1, limit = 20) {
    return this.tickets.findMany({
      where: { customerId },
      order: { lastMessageAt: 'DESC', createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
  }

  async create(customerId: string, dto: CreateSupportTicketDto) {
    if (!dto.message.trim() || !dto.subject.trim())
      throw new BadRequestException('Subject and message are required');
    if (
      dto.orderId &&
      !(await this.dataSource
        .getRepository(Order)
        .findOne({ where: { id: dto.orderId, customerId } }))
    )
      throw new NotFoundException('Order not found');
    return this.dataSource.transaction(async (manager) => {
      const now = new Date();
      const ticket = await manager.getRepository(SupportTicket).save(
        manager.getRepository(SupportTicket).create({
          customerId,
          orderId: dto.orderId,
          category: dto.category,
          subject: dto.subject.trim(),
          status: 'open',
          priority: dto.priority ?? 'normal',
          lastMessageAt: now,
          staffUnreadCount: 1,
          customerUnreadCount: 0,
        }),
      );
      const message = await manager.getRepository(SupportMessage).save(
        manager.getRepository(SupportMessage).create({
          ticketId: ticket.id,
          authorUserId: customerId,
          authorType: 'customer',
          body: dto.message.trim(),
        }),
      );
      await this.enqueueMessage(manager, ticket, message);
      return ticket;
    });
  }

  async detail(userId: string, id: string, role = 'customer') {
    const ticket = await this.authorizedTicket(userId, id, role, false);
    return {
      ticket,
      unreadCount: this.isStaff(role)
        ? ticket.staffUnreadCount
        : ticket.customerUnreadCount,
    };
  }

  async history(
    userId: string,
    ticketId: string,
    role: string,
    page = 1,
    limit = 50,
  ) {
    await this.authorizedTicket(userId, ticketId, role, false);
    const [items, total] = await this.dataSource
      .getRepository(SupportMessage)
      .findAndCount({
        where: { ticketId },
        order: { createdAt: 'ASC', id: 'ASC' },
        skip: (page - 1) * limit,
        take: limit,
      });
    return { items, page, limit, total };
  }

  async addMessage(
    userId: string,
    ticketId: string,
    role: string,
    dto: CreateSupportMessageDto,
  ) {
    const body = dto.body.trim();
    if (!body) throw new BadRequestException('Message is required');
    return this.dataSource.transaction(async (manager) => {
      const repo = manager.getRepository(SupportTicket);
      const ticket = await repo.findOne({
        where: { id: ticketId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!ticket || !(await this.canAccess(userId, role, ticket, true)))
        throw new NotFoundException('Support ticket not found');
      if (['resolved', 'closed'].includes(ticket.status))
        throw new ConflictException('Support ticket is closed');
      await this.validateAttachments(
        manager,
        userId,
        ticket,
        dto.attachmentMediaIds ?? [],
      );
      const staff = this.isStaff(role);
      const message = await manager.getRepository(SupportMessage).save(
        manager.getRepository(SupportMessage).create({
          ticketId,
          authorUserId: userId,
          authorType: staff ? 'staff' : 'customer',
          body,
        }),
      );
      if (dto.attachmentMediaIds?.length)
        await manager
          .getRepository(SupportMessageAttachment)
          .save(
            dto.attachmentMediaIds.map((mediaAssetId) =>
              manager
                .getRepository(SupportMessageAttachment)
                .create({ supportMessageId: message.id, mediaAssetId }),
            ),
          );
      ticket.lastMessageAt = new Date();
      if (staff) {
        ticket.customerUnreadCount += 1;
        ticket.status = 'waiting_customer';
      } else {
        ticket.staffUnreadCount += 1;
        if (ticket.assignedStaffUserId) ticket.status = 'in_progress';
      }
      await repo.save(ticket);
      await this.enqueueMessage(manager, ticket, message);
      return message;
    });
  }

  async markRead(userId: string, ticketId: string, role: string) {
    return this.dataSource.transaction(async (manager) => {
      const repo = manager.getRepository(SupportTicket);
      const ticket = await repo.findOne({
        where: { id: ticketId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!ticket || !(await this.canAccess(userId, role, ticket, false)))
        throw new NotFoundException('Support ticket not found');
      const now = new Date();
      if (this.isStaff(role)) {
        ticket.staffUnreadCount = 0;
        ticket.staffLastReadAt = now;
      } else {
        ticket.customerUnreadCount = 0;
        ticket.customerLastReadAt = now;
      }
      await repo.save(ticket);
      await this.outbox.enqueue(manager, {
        aggregateType: 'support_ticket',
        aggregateId: ticket.id,
        eventType: 'support.messages.read',
        payload: {
          ticketId: ticket.id,
          readerType: this.isStaff(role) ? 'staff' : 'customer',
        },
      });
      return ticket;
    });
  }

  async queue(
    userId: string,
    filters: {
      page?: number;
      limit?: number;
      assigned?: string;
      status?: string;
      priority?: string;
    },
  ) {
    const page = filters.page ?? 1,
      limit = filters.limit ?? 20;
    const qb = this.dataSource
      .getRepository(SupportTicket)
      .createQueryBuilder('ticket');
    if (filters.assigned === 'me')
      qb.andWhere('ticket.assigned_staff_user_id=:userId', { userId });
    if (filters.assigned === 'unassigned')
      qb.andWhere('ticket.assigned_staff_user_id IS NULL');
    if (filters.status)
      qb.andWhere('ticket.status=:status', { status: filters.status });
    if (filters.priority)
      qb.andWhere('ticket.priority=:priority', { priority: filters.priority });
    qb.orderBy(
      `CASE ticket.priority WHEN 'urgent' THEN 4 WHEN 'high' THEN 3 WHEN 'normal' THEN 2 ELSE 1 END`,
      'DESC',
    )
      .addOrderBy('ticket.staff_unread_count', 'DESC')
      .addOrderBy('COALESCE(ticket.last_message_at,ticket.created_at)', 'ASC')
      .skip((page - 1) * limit)
      .take(limit);
    const [items, total] = await qb.getManyAndCount();
    return { items, page, limit, total };
  }

  async claim(agentId: string, ticketId: string) {
    return this.dataSource.transaction(async (manager) => {
      const ticket = await manager.getRepository(SupportTicket).findOne({
        where: { id: ticketId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!ticket) throw new NotFoundException('Support ticket not found');
      if (ticket.assignedStaffUserId && ticket.assignedStaffUserId !== agentId)
        throw new ConflictException('Support ticket is already assigned');
      if (['resolved', 'closed'].includes(ticket.status))
        throw new ConflictException('Support ticket is closed');
      ticket.assignedStaffUserId = agentId;
      ticket.assignedAt = ticket.assignedAt ?? new Date();
      ticket.status = 'in_progress';
      await manager.getRepository(SupportTicket).save(ticket);
      await this.outbox.enqueue(manager, {
        aggregateType: 'support_ticket',
        aggregateId: ticket.id,
        eventType: 'support.ticket.assigned',
        payload: { ticketId: ticket.id, agentId },
      });
      return ticket;
    });
  }

  async changeStatus(
    agentId: string,
    ticketId: string,
    role: string,
    status: string,
  ) {
    return this.dataSource.transaction(async (manager) => {
      const ticket = await manager.getRepository(SupportTicket).findOne({
        where: { id: ticketId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!ticket || !(await this.canAccess(agentId, role, ticket, true)))
        throw new NotFoundException('Support ticket not found');
      ticket.status = status;
      ticket.resolvedAt = status === 'resolved' ? new Date() : null;
      ticket.closedAt = status === 'closed' ? new Date() : null;
      await manager.getRepository(SupportTicket).save(ticket);
      await this.outbox.enqueue(manager, {
        aggregateType: 'support_ticket',
        aggregateId: ticket.id,
        eventType: 'support.ticket.status_changed',
        payload: { ticketId: ticket.id, status },
      });
      return ticket;
    });
  }

  async realtimeAuthorization(userId: string, ticketId: string, role: string) {
    await this.authorizedTicket(userId, ticketId, role, false);
    return {
      channel: `/support/${ticketId}`,
      expiresAt: new Date(Date.now() + 5 * 60_000),
    };
  }

  private async authorizedTicket(
    userId: string,
    id: string,
    role: string,
    writing: boolean,
  ) {
    const ticket = await this.tickets.findById(id);
    if (!ticket || !(await this.canAccess(userId, role, ticket, writing)))
      throw new NotFoundException('Support ticket not found');
    return ticket;
  }
  private canAccess(
    userId: string,
    role: string,
    ticket: SupportTicket,
    writing: boolean,
  ) {
    if (!this.isStaff(role))
      return Promise.resolve(ticket.customerId === userId);
    if (role === 'admin') return Promise.resolve(true);
    return Promise.resolve(!writing || ticket.assignedStaffUserId === userId);
  }
  private isStaff(role: string) {
    return ['admin', 'support'].includes(role);
  }
  private async validateAttachments(
    manager: any,
    userId: string,
    ticket: SupportTicket,
    ids: string[],
  ) {
    if (!ids.length) return;
    const assets = await manager.getRepository(MediaAsset).findByIds(ids);
    if (
      assets.length !== ids.length ||
      assets.some(
        (a: MediaAsset) =>
          a.status !== 'active' ||
          a.purpose !== 'support_attachment' ||
          a.targetId !== ticket.id ||
          a.uploadedByUserId !== userId,
      )
    ) {
      throw new ForbiddenException('Attachment is not authorized');
    }
  }
  private enqueueMessage(
    manager: any,
    ticket: SupportTicket,
    message: SupportMessage,
  ) {
    return this.outbox.enqueue(manager, {
      aggregateType: 'support_message',
      aggregateId: message.id,
      eventType: 'support.message.created',
      payload: {
        ticketId: ticket.id,
        messageId: message.id,
        authorType: message.authorType,
        customerId: ticket.customerId,
        assignedStaffUserId: ticket.assignedStaffUserId,
      },
    });
  }
}
