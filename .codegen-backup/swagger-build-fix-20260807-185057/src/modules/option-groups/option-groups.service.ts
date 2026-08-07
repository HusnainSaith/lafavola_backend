import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { OptionGroupRepository } from './repositories/option-group.repository';
import { OptionGroup } from './entities/option-group.entity';
import { OptionChoice } from './entities/option-choice.entity';
import { CreateOptionGroupDto } from './dto/create-option-group.dto';
import { UpdateOptionGroupDto } from './dto/update-option-group.dto';
import { CreateOptionChoiceDto } from './dto/create-option-choice.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class OptionGroupsService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly groups: OptionGroupRepository,
  ) {}

  list(restaurantId?: string) {
    return this.groups.findMany({
      where: restaurantId
        ? { restaurantId, isActive: true }
        : { isActive: true },
      order: { displayOrder: 'ASC', createdAt: 'ASC' },
    });
  }

  async detail(id: string) {
    return requireEntity(
      await this.groups.findById(id),
      'Option group not found',
    );
  }

  create(dto: CreateOptionGroupDto) {
    return this.groups.save(
      this.groups.create({
        ...dto,
        minSelect: dto.minSelect ?? 0,
        isRequired: dto.isRequired ?? false,
        allowQuantity: dto.allowQuantity ?? false,
        displayOrder: dto.displayOrder ?? 0,
        isActive: dto.isActive ?? true,
      }),
    );
  }

  async update(id: string, dto: UpdateOptionGroupDto) {
    const group = await this.detail(id);
    Object.assign(group, dto);
    return this.groups.save(group);
  }

  async addChoice(groupId: string, dto: CreateOptionChoiceDto) {
    await this.detail(groupId);
    return this.dataSource.getRepository(OptionChoice).save(
      this.dataSource.getRepository(OptionChoice).create({
        ...dto,
        optionGroupId: groupId,
        priceAdjustmentMinor: dto.priceAdjustmentMinor ?? 0,
        caloriesAdjustment: dto.caloriesAdjustment ?? 0,
        isDefault: dto.isDefault ?? false,
        displayOrder: dto.displayOrder ?? 0,
        isActive: dto.isActive ?? true,
      }),
    );
  }
}
