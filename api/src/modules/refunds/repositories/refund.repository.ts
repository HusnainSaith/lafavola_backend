import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Refund } from '../entities/refund.entity';

@Injectable()
export class RefundRepository extends BaseRepository<Refund> {
  constructor(dataSource: DataSource) {
    super(dataSource, Refund);
  }
}
