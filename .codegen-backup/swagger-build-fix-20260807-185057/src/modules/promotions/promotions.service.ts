import { Injectable } from '@nestjs/common';
import { PromotionRepository } from './repositories/promotion.repository';
import { Promotion } from './entities/promotion.entity';
import { CreatePromotionDto } from './dto/create-promotion.dto';
import { UpdatePromotionDto } from './dto/update-promotion.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class PromotionsService {
  constructor(private readonly repository: PromotionRepository) {}

  findAll(): Promise<Promotion[]> {
    return this.repository.findMany({ order: { createdAt: 'DESC' } });
  }

  async findById(id: string): Promise<Promotion> {
    return requireEntity(
      await this.repository.findById(id),
      'Promotions record not found',
    );
  }

  create(dto: CreatePromotionDto): Promise<Promotion> {
    return this.repository.save(
      this.repository.create(dto as Partial<Promotion>),
    );
  }

  async update(id: string, dto: UpdatePromotionDto): Promise<Promotion> {
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
