import { Module } from '@nestjs/common';
import { CartsModule } from '../carts/carts.module';
import { PricingModule } from '../pricing/pricing.module';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { OrderRepository } from './repositories/order.repository';
import { CheckoutModule } from '../checkout/checkout.module';

@Module({
  imports: [CartsModule, PricingModule, CheckoutModule],
  controllers: [OrdersController],
  providers: [OrdersService, OrderRepository],
  exports: [OrdersService, OrderRepository],
})
export class OrdersModule {}
