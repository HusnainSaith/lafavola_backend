import { Injectable } from '@nestjs/common';
import { requireEntity } from '../../common/utils/service-errors.util';
import { NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { StaffMember } from '../staff/entities/staff-member.entity';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { MenuCategory } from './entities/menu-category.entity';
import { MenuCategoryRepository } from './repositories/menu-category.repository';

@Injectable()
export class CategoriesService {
  constructor(
    private readonly repository: MenuCategoryRepository,
    private readonly dataSource: DataSource,
  ) {}

  findAll(): Promise<MenuCategory[]> {
    return this.repository.findMany({ order: { createdAt: 'DESC' } });
  }

  async findById(id: string): Promise<MenuCategory> {
    return requireEntity(
      await this.repository.findById(id),
      'Categories record not found',
    );
  }

  async create(
    dto: CreateCategoryDto,
    actorUserId: string,
  ): Promise<MenuCategory> {
    const restaurantId = await this.restaurantForActor(actorUserId);
    if (dto.restaurantId !== restaurantId) {
      throw new NotFoundException('Restaurant not found');
    }
    return this.repository.save(
      this.repository.create(dto as Partial<MenuCategory>),
    );
  }

  async update(
    id: string,
    dto: UpdateCategoryDto,
    actorUserId: string,
  ): Promise<MenuCategory> {
    const restaurantId = await this.restaurantForActor(actorUserId);
    const entity = await this.repository.findOne({
      where: { id, restaurantId },
    });
    if (!entity) throw new NotFoundException('Categories record not found');
    if (dto.restaurantId && dto.restaurantId !== restaurantId) {
      throw new NotFoundException('Restaurant not found');
    }
    Object.assign(entity, dto);
    return this.repository.save(entity);
  }

  async remove(id: string, actorUserId: string): Promise<void> {
    const restaurantId = await this.restaurantForActor(actorUserId);
    const entity = await this.repository.findOne({
      where: { id, restaurantId },
    });
    if (!entity) throw new NotFoundException('Categories record not found');
    (entity as any).isActive = false;
    await this.repository.save(entity);
  }

  private async restaurantForActor(actorUserId: string) {
    const staff = await this.dataSource.getRepository(StaffMember).findOne({
      where: { userId: actorUserId, isActive: true },
      select: { restaurantId: true },
    });
    if (!staff) throw new NotFoundException('Staff member not found');
    return staff.restaurantId;
  }
}
