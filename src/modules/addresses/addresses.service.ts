import { Injectable, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { CreateAddressDto } from './dto/create-address.dto';
import { UpdateAddressDto } from './dto/update-address.dto';
import { CustomerAddress } from './entities/customer-address.entity';
import { CustomerAddressRepository } from './repositories/customer-address.repository';

@Injectable()
export class AddressesService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly addresses: CustomerAddressRepository,
  ) {}

  list(customerId: string) {
    return this.addresses.findActiveForCustomer(customerId);
  }

  async create(customerId: string, dto: CreateAddressDto) {
    return this.dataSource.transaction(async (manager) => {
      const repo = manager.getRepository(CustomerAddress);
      if (dto.isDefault) {
        await repo.update(
          { customerId, isDefault: true },
          { isDefault: false },
        );
      }
      return repo.save(
        repo.create({
          ...dto,
          customerId,
          countryCode: dto.countryCode ?? 'IT',
          isActive: true,
          isDefault: dto.isDefault ?? false,
        }),
      );
    });
  }

  async update(customerId: string, id: string, dto: UpdateAddressDto) {
    return this.dataSource.transaction(async (manager) => {
      const repo = manager.getRepository(CustomerAddress);
      const address = await repo.findOne({
        where: { id, customerId, isActive: true },
      });
      if (!address) throw new NotFoundException('Address not found');
      if (dto.isDefault) {
        await repo.update(
          { customerId, isDefault: true },
          { isDefault: false },
        );
      }
      Object.assign(address, dto);
      return repo.save(address);
    });
  }

  async remove(customerId: string, id: string) {
    const address = await this.addresses.findOne({
      where: { id, customerId, isActive: true },
    });
    if (!address) throw new NotFoundException('Address not found');
    address.isActive = false;
    address.isDefault = false;
    await this.addresses.save(address);
  }
}
