import { Global, Module } from '@nestjs/common';
import { AuditService } from './audit.service';
import { AuditLogRepository } from './repositories/audit-log.repository';
import { AuditController } from './audit.controller';

@Global()
@Module({
  controllers: [AuditController],
  providers: [AuditService, AuditLogRepository],
  exports: [AuditService],
})
export class AuditModule {}
