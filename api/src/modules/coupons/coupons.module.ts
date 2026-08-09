import { Module } from '@nestjs/common';
import { CouponsController } from './coupons.controller';
import { CouponsService } from './coupons.service';
import { CouponRepository } from './repositories/coupon.repository';

@Module({
  controllers: [CouponsController],
  providers: [CouponsService, CouponRepository],
  exports: [CouponsService, CouponRepository],
})
export class CouponsModule {}
