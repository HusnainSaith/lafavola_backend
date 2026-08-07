import { Injectable } from '@nestjs/common';
import { AuditLogRepository } from './repositories/audit-log.repository';
import { AuditContext } from './interfaces/audit-context.interface';

@Injectable()
export class AuditService {
  constructor(private readonly logs: AuditLogRepository) {}

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
