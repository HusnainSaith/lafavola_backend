import { Module } from '@nestjs/common';
import { PricingModule } from '../pricing/pricing.module';
import { CartsController } from './carts.controller';
import { CartsService } from './carts.service';
import { CartRepository } from './repositories/cart.repository';

@Module({
  imports: [PricingModule],
  controllers: [CartsController],
  providers: [CartsService, CartRepository],
  exports: [CartsService],
})
export class CartsModule {}
