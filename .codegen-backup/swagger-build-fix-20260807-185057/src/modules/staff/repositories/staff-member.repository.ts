import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { StaffMember } from '../entities/staff-member.entity';

@Injectable()
export class StaffMemberRepository extends BaseRepository<StaffMember> {
  constructor(dataSource: DataSource) {
    super(dataSource, StaffMember);
  }
}
