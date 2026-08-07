import { Module } from '@nestjs/common';
import { CustomersController } from './customers.controller';
import { CustomersService } from './customers.service';
import { CustomerProfileRepository } from './repositories/customer-profile.repository';

@Module({
  controllers: [CustomersController],
  providers: [CustomersService, CustomerProfileRepository],
  exports: [CustomersService],
})
export class CustomersModule {}
