import { Injectable } from '@nestjs/common';
import { IngredientRepository } from './repositories/ingredient.repository';
import { Ingredient } from './entities/ingredient.entity';
import { CreateIngredientDto } from './dto/create-ingredient.dto';
import { UpdateIngredientDto } from './dto/update-ingredient.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class IngredientsService {
  constructor(private readonly repository: IngredientRepository) {}

  findAll(): Promise<Ingredient[]> {
    return this.repository.findMany({ order: { createdAt: 'DESC' } });
  }

  async findById(id: string): Promise<Ingredient> {
    return requireEntity(
      await this.repository.findById(id),
      'Ingredients record not found',
    );
  }

  create(dto: CreateIngredientDto): Promise<Ingredient> {
    return this.repository.save(
      this.repository.create(dto as Partial<Ingredient>),
    );
  }

  async update(id: string, dto: UpdateIngredientDto): Promise<Ingredient> {
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
