import { Injectable } from '@nestjs/common';
import { requireEntity } from '../../common/utils/service-errors.util';
import { CreateFaqDto } from './dto/create-faq.dto';
import { UpdateFaqDto } from './dto/update-faq.dto';
import { FaqArticle } from './entities/faq-article.entity';
import { FaqArticleRepository } from './repositories/faq-article.repository';

@Injectable()
export class FaqService {
  constructor(private readonly repository: FaqArticleRepository) {}

  findAll(): Promise<FaqArticle[]> {
    return this.repository.findMany({ order: { createdAt: 'DESC' } });
  }

  async findById(id: string): Promise<FaqArticle> {
    return requireEntity(
      await this.repository.findById(id),
      'Faq record not found',
    );
  }

  create(dto: CreateFaqDto): Promise<FaqArticle> {
    return this.repository.save(
      this.repository.create(dto as Partial<FaqArticle>),
    );
  }

  async update(id: string, dto: UpdateFaqDto): Promise<FaqArticle> {
    const entity = await this.findById(id);
    Object.assign(entity, dto);
    return this.repository.save(entity);
  }

  async remove(id: string): Promise<void> {
    const entity = await this.findById(id);
    (entity as any).isActive = false;
    await this.repository.save(entity);
  }
}
