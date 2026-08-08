import { Module } from '@nestjs/common';
import { PAYMENT_PROVIDER } from '../../modules/payments/interfaces/payment-provider.interface';
import { SumUpPaymentProvider } from './sumup-payment.provider';

@Module({
  providers: [
    SumUpPaymentProvider,
    { provide: PAYMENT_PROVIDER, useExisting: SumUpPaymentProvider },
  ],
  exports: [PAYMENT_PROVIDER],
})
export class SumUpModule {}
