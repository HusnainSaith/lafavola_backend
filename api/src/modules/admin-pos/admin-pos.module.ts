import { Module } from '@nestjs/common';
import { PaymentsModule } from '../payments/payments.module';
import { PricingModule } from '../pricing/pricing.module';
import { AdminPosController } from './admin-pos.controller';
import { AdminPosService } from './admin-pos.service';

@Module({
  imports: [PricingModule, PaymentsModule],
  controllers: [AdminPosController],
  providers: [AdminPosService],
  exports: [AdminPosService],
})
export class AdminPosModule {}
