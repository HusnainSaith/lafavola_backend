import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { LoyaltyAccount } from '../entities/loyalty-account.entity';

@Injectable()
export class LoyaltyAccountRepository extends BaseRepository<LoyaltyAccount> {
  constructor(dataSource: DataSource) {
    super(dataSource, LoyaltyAccount);
  }

  findByCustomerId(customerId: string): Promise<LoyaltyAccount | null> {
    return this.repository.findOne({ where: { customerId } });
  }
}
