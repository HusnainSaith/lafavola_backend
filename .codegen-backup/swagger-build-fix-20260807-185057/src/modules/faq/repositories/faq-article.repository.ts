import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { FaqArticle } from '../entities/faq-article.entity';

@Injectable()
export class FaqArticleRepository extends BaseRepository<FaqArticle> {
  constructor(dataSource: DataSource) {
    super(dataSource, FaqArticle);
  }
}
