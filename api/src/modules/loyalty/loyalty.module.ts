import { Module } from '@nestjs/common';
import { LoyaltyController } from './loyalty.controller';
import { LoyaltyService } from './loyalty.service';
import { LoyaltyAccountRepository } from './repositories/loyalty-account.repository';

@Module({
  controllers: [LoyaltyController],
  providers: [LoyaltyService, LoyaltyAccountRepository],
  exports: [LoyaltyService],
})
export class LoyaltyModule {}
