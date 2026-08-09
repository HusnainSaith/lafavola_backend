import { Module } from '@nestjs/common';
import { IngredientsController } from './ingredients.controller';
import { IngredientsService } from './ingredients.service';
import { IngredientRepository } from './repositories/ingredient.repository';

@Module({
  controllers: [IngredientsController],
  providers: [IngredientsService, IngredientRepository],
  exports: [IngredientsService, IngredientRepository],
})
export class IngredientsModule {}
