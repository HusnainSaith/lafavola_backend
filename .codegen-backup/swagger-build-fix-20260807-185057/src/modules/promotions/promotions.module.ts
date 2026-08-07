import { Module } from '@nestjs/common';
import { PromotionsController } from './promotions.controller';
import { PromotionsService } from './promotions.service';
import { PromotionRepository } from './repositories/promotion.repository';

@Module({
  controllers: [PromotionsController],
  providers: [PromotionsService, PromotionRepository],
  exports: [PromotionsService, PromotionRepository],
})
export class PromotionsModule {}
