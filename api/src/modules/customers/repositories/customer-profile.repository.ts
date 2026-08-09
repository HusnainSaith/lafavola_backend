import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { CustomerProfile } from '../entities/customer-profile.entity';

@Injectable()
export class CustomerProfileRepository extends BaseRepository<CustomerProfile> {
  constructor(dataSource: DataSource) {
    super(dataSource, CustomerProfile);
  }
}
