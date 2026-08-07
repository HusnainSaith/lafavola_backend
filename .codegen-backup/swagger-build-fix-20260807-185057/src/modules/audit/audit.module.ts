import { Global, Module } from '@nestjs/common';
import { AuditService } from './audit.service';
import { AuditLogRepository } from './repositories/audit-log.repository';

@Global()
@Module({
  providers: [AuditService, AuditLogRepository],
  exports: [AuditService],
})
export class AuditModule {}
