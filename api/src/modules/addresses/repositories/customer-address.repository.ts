import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { CustomerAddress } from '../entities/customer-address.entity';

@Injectable()
export class CustomerAddressRepository extends BaseRepository<CustomerAddress> {
  constructor(dataSource: DataSource) {
    super(dataSource, CustomerAddress);
  }

  findActiveForCustomer(customerId: string): Promise<CustomerAddress[]> {
    return this.repository.find({
      where: { customerId, isActive: true },
      order: { isDefault: 'DESC', createdAt: 'DESC' },
    });
  }
}
