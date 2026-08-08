import { Module } from '@nestjs/common';
import { StaffMemberRepository } from './repositories/staff-member.repository';
import { StaffController } from './staff.controller';
import { StaffService } from './staff.service';

@Module({
  controllers: [StaffController],
  providers: [StaffService, StaffMemberRepository],
  exports: [StaffService],
})
export class StaffModule {}
