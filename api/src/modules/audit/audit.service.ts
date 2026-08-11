import { Injectable, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { AdminListQueryDto } from '../../common/dto/admin-list-query.dto';
import { StaffMember } from '../staff/entities/staff-member.entity';
import { AuditLog } from './entities/audit-log.entity';
import { AuditContext } from './interfaces/audit-context.interface';
import { AuditLogRepository } from './repositories/audit-log.repository';

@Injectable()
export class AuditService {
  constructor(
    private readonly logs: AuditLogRepository,
    private readonly dataSource: DataSource,
  ) {}

  async listAdmin(actorUserId: string, query: AdminListQueryDto) {
    const staff = await this.dataSource.getRepository(StaffMember).findOne({
      where: { userId: actorUserId, isActive: true },
    });
    if (!staff) throw new NotFoundException('Staff member not found');
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? 20;
    const builder = this.dataSource
      .getRepository(AuditLog)
      .createQueryBuilder('audit')
      .leftJoinAndSelect('audit.actorUser', 'actor')
      .where('audit.restaurant_id = :restaurantId', {
        restaurantId: staff.restaurantId,
      })
      .orderBy('audit.createdAt', 'DESC')
      .skip((page - 1) * pageSize)
      .take(pageSize);
    if (query.search) {
      builder.andWhere(
        '(audit.action ILIKE :search OR audit.resource_type ILIKE :search)',
        { search: `%${query.search}%` },
      );
    }
    const [data, total] = await builder.getManyAndCount();
    return {
      data,
      meta: { page, pageSize, total, totalPages: Math.ceil(total / pageSize) },
    };
  }

  record(
    action: string,
    resourceType: string,
    resourceId: string | undefined,
    context: AuditContext,
    beforeData?: unknown,
    afterData?: unknown,
  ) {
    return this.logs.save(
      this.logs.create({
        actorUserId: context.actorUserId,
        action,
        resourceType,
        resourceId,
        restaurantId: context.restaurantId,
        correlationId: context.correlationId,
        ipAddress: context.ipAddress,
        userAgent: context.userAgent,
        beforeData: beforeData as any,
        afterData: afterData as any,
        metadata: context.metadata ?? {},
      }),
    );
  }
}
