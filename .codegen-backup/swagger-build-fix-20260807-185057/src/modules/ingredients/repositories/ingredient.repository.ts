import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Ingredient } from '../entities/ingredient.entity';

@Injectable()
export class IngredientRepository extends BaseRepository<Ingredient> {
  constructor(dataSource: DataSource) {
    super(dataSource, Ingredient);
  }
}
