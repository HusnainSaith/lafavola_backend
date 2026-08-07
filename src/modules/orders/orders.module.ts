import { Module } from '@nestjs/common';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { OrderRepository } from './repositories/order.repository';

@Module({
  controllers: [OrdersController],
  providers: [OrdersService, OrderRepository],
  exports: [OrdersService, OrderRepository],
})
export class OrdersModule {}
