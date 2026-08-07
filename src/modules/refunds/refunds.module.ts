import { Module } from '@nestjs/common';
import { RefundsController } from './refunds.controller';
import { RefundsService } from './refunds.service';
import { RefundRepository } from './repositories/refund.repository';

@Module({
  controllers: [RefundsController],
  providers: [RefundsService, RefundRepository],
  exports: [RefundsService],
})
export class RefundsModule {}
