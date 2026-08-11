import { Injectable, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { requireEntity } from '../../common/utils/service-errors.util';
import { Ingredient } from '../ingredients/entities/ingredient.entity';
import { StaffMember } from '../staff/entities/staff-member.entity';
import { CreateOptionChoiceDto } from './dto/create-option-choice.dto';
import { CreateOptionGroupDto } from './dto/create-option-group.dto';
import { UpdateOptionChoiceDto } from './dto/update-option-choice.dto';
import { UpdateOptionGroupDto } from './dto/update-option-group.dto';
import { OptionChoice } from './entities/option-choice.entity';
import { OptionGroupRepository } from './repositories/option-group.repository';

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
    const group = requireEntity(
      await this.groups.findById(id),
      'Option group not found',
    );
    const choices = await this.dataSource.getRepository(OptionChoice).find({
      where: { optionGroupId: id, isActive: true },
      order: { displayOrder: 'ASC', createdAt: 'ASC' },
    });
    return { ...group, choices };
  }

  async create(dto: CreateOptionGroupDto, actorUserId: string) {
    const actor = await this.findActiveStaff(actorUserId);
    if (dto.restaurantId !== actor.restaurantId) {
      throw new NotFoundException('Restaurant not found');
    }
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

  async update(id: string, dto: UpdateOptionGroupDto, actorUserId: string) {
    const group = await this.findGroupForActor(id, actorUserId);
    if (dto.restaurantId && dto.restaurantId !== group.restaurantId) {
      throw new NotFoundException('Restaurant not found');
    }
    Object.assign(group, dto);
    return this.groups.save(group);
  }

  async deactivate(id: string, actorUserId: string) {
    const group = await this.findGroupForActor(id, actorUserId);
    group.isActive = false;
    return this.groups.save(group);
  }

  async addChoice(
    groupId: string,
    dto: CreateOptionChoiceDto,
    actorUserId: string,
  ) {
    await this.findGroupForActor(groupId, actorUserId);
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

  async updateChoice(
    groupId: string,
    choiceId: string,
    dto: UpdateOptionChoiceDto,
    actorUserId: string,
  ) {
    const { choice, group } = await this.findChoice(
      actorUserId,
      groupId,
      choiceId,
    );
    if (dto.ingredientId) {
      requireEntity(
        await this.dataSource.getRepository(Ingredient).findOne({
          where: {
            id: dto.ingredientId,
            restaurantId: group.restaurantId,
            isActive: true,
          },
        }),
        'Ingredient not found',
      );
    }
    Object.assign(choice, dto);
    return this.dataSource.getRepository(OptionChoice).save(choice);
  }

  async deactivateChoice(
    groupId: string,
    choiceId: string,
    actorUserId: string,
  ) {
    const { choice } = await this.findChoice(actorUserId, groupId, choiceId);
    choice.isActive = false;
    return this.dataSource.getRepository(OptionChoice).save(choice);
  }

  private async findChoice(
    actorUserId: string,
    groupId: string,
    choiceId: string,
  ) {
    const group = await this.findGroupForActor(groupId, actorUserId);
    const choice = await this.dataSource.getRepository(OptionChoice).findOne({
      where: { id: choiceId, optionGroupId: groupId },
    });
    if (!choice) throw new NotFoundException('Option choice not found');
    return { choice, group };
  }

  private async findActiveStaff(actorUserId: string) {
    return requireEntity(
      await this.dataSource.getRepository(StaffMember).findOne({
        where: { userId: actorUserId, isActive: true },
      }),
      'Staff member not found',
    );
  }

  private async findGroupForActor(id: string, actorUserId: string) {
    const actor = await this.findActiveStaff(actorUserId);
    return requireEntity(
      await this.groups.findOne({
        where: { id, restaurantId: actor.restaurantId },
      }),
      'Option group not found',
    );
  }
}
