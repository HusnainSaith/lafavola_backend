import { Module } from '@nestjs/common';
import { CategoriesController } from './categories.controller';
import { CategoriesService } from './categories.service';
import { MenuCategoryRepository } from './repositories/menu-category.repository';

@Module({
  controllers: [CategoriesController],
  providers: [CategoriesService, MenuCategoryRepository],
  exports: [CategoriesService, MenuCategoryRepository],
})
export class CategoriesModule {}
