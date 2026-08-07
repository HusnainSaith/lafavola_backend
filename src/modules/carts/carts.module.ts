import { Module } from '@nestjs/common';
import { CartsController } from './carts.controller';
import { CartsService } from './carts.service';
import { CartRepository } from './repositories/cart.repository';
import { PricingModule } from '../pricing/pricing.module';

@Module({
  imports: [PricingModule],
  controllers: [CartsController],
  providers: [CartsService, CartRepository],
  exports: [CartsService],
})
export class CartsModule {}
