import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { MenuCategory } from '../entities/menu-category.entity';

@Injectable()
export class MenuCategoryRepository extends BaseRepository<MenuCategory> {
  constructor(dataSource: DataSource) {
    super(dataSource, MenuCategory);
  }
}
