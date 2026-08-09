import { Module } from '@nestjs/common';
import { SumUpModule } from '../../integrations/sumup/sumup.module';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { PaymentTransactionRepository } from './repositories/payment-transaction.repository';

@Module({
  imports: [SumUpModule],
  controllers: [PaymentsController],
  providers: [PaymentsService, PaymentTransactionRepository],
  exports: [PaymentsService, SumUpModule],
})
export class PaymentsModule {}
