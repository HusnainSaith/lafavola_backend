import { Module } from '@nestjs/common';
import { CartsModule } from '../carts/carts.module';
import { LoyaltyModule } from '../loyalty/loyalty.module';
import { PricingModule } from '../pricing/pricing.module';
import { PromotionsModule } from '../promotions/promotions.module';
import { RestaurantsModule } from '../restaurants/restaurants.module';
import { CheckoutController } from './checkout.controller';
import { CheckoutService } from './checkout.service';

@Module({
  imports: [
    CartsModule,
    PricingModule,
    PromotionsModule,
    RestaurantsModule,
    LoyaltyModule,
  ],
  controllers: [CheckoutController],
  providers: [CheckoutService],
  exports: [CheckoutService],
})
export class CheckoutModule {}
