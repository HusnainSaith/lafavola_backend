import { Module } from '@nestjs/common';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { PaymentTransactionRepository } from './repositories/payment-transaction.repository';

@Module({
  controllers: [PaymentsController],
  providers: [PaymentsService, PaymentTransactionRepository],
  exports: [PaymentsService],
})
export class PaymentsModule {}
