import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { PaymentTransaction } from '../entities/payment-transaction.entity';

@Injectable()
export class PaymentTransactionRepository extends BaseRepository<PaymentTransaction> {
  constructor(dataSource: DataSource) {
    super(dataSource, PaymentTransaction);
  }
}
