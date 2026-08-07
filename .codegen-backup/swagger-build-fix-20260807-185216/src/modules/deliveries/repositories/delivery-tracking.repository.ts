import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { DeliveryTracking } from '../entities/delivery-tracking.entity';

@Injectable()
export class DeliveryTrackingRepository extends BaseRepository<DeliveryTracking> {
  constructor(dataSource: DataSource) {
    super(dataSource, DeliveryTracking);
  }

  findByOrderId(orderId: string): Promise<DeliveryTracking | null> {
    return this.repository.findOne({ where: { orderId } });
  }
}
