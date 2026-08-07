import { Module } from '@nestjs/common';
import { DeliveriesController } from './deliveries.controller';
import { DeliveriesService } from './deliveries.service';
import { DeliveryTrackingRepository } from './repositories/delivery-tracking.repository';

@Module({
  controllers: [DeliveriesController],
  providers: [DeliveriesService, DeliveryTrackingRepository],
  exports: [DeliveriesService],
})
export class DeliveriesModule {}
