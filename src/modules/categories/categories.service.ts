import { Injectable } from '@nestjs/common';
import { MenuCategoryRepository } from './repositories/menu-category.repository';
import { MenuCategory } from './entities/menu-category.entity';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class CategoriesService {
  constructor(private readonly repository: MenuCategoryRepository) {}

  findAll(): Promise<MenuCategory[]> {
    return this.repository.findMany({ order: { createdAt: 'DESC' } });
  }

  async findById(id: string): Promise<MenuCategory> {
    return requireEntity(
      await this.repository.findById(id),
      'Categories record not found',
    );
  }

  create(dto: CreateCategoryDto): Promise<MenuCategory> {
    return this.repository.save(
      this.repository.create(dto as Partial<MenuCategory>),
    );
  }

  async update(id: string, dto: UpdateCategoryDto): Promise<MenuCategory> {
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
