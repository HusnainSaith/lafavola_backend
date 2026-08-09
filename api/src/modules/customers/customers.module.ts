import { Module } from '@nestjs/common';
import { CustomersController } from './customers.controller';
import { CustomersService } from './customers.service';
import { CustomerProfileRepository } from './repositories/customer-profile.repository';
import { PrivacyController } from './privacy.controller';

@Module({
  controllers: [CustomersController, PrivacyController],
  providers: [CustomersService, CustomerProfileRepository],
  exports: [CustomersService],
})
export class CustomersModule {}
