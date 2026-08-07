import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Order } from '../entities/order.entity';

@Injectable()
export class OrderRepository extends BaseRepository<Order> {
  constructor(dataSource: DataSource) {
    super(dataSource, Order);
  }

  findByOrderNumber(orderNumber: string): Promise<Order | null> {
    return this.repository.findOne({ where: { orderNumber } });
  }

  findCustomerHistory(
    customerId: string,
    take = 20,
    skip = 0,
  ): Promise<Order[]> {
    return this.repository.find({
      where: { customerId },
      order: { createdAt: 'DESC' },
      take,
      skip,
    });
  }
}
