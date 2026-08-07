import { Module } from '@nestjs/common';
import { FaqController } from './faq.controller';
import { FaqService } from './faq.service';
import { FaqArticleRepository } from './repositories/faq-article.repository';

@Module({
  controllers: [FaqController],
  providers: [FaqService, FaqArticleRepository],
  exports: [FaqService, FaqArticleRepository],
})
export class FaqModule {}
