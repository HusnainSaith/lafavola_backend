import { Module } from '@nestjs/common';
import { AddressesController } from './addresses.controller';
import { AddressesService } from './addresses.service';
import { CustomerAddressRepository } from './repositories/customer-address.repository';

@Module({
  controllers: [AddressesController],
  providers: [AddressesService, CustomerAddressRepository],
  exports: [AddressesService],
})
export class AddressesModule {}
