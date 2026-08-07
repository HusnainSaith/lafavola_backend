import { Module } from '@nestjs/common';
import { StaffController } from './staff.controller';
import { StaffService } from './staff.service';
import { StaffMemberRepository } from './repositories/staff-member.repository';

@Module({
  controllers: [StaffController],
  providers: [StaffService, StaffMemberRepository],
  exports: [StaffService],
})
export class StaffModule {}
