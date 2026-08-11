import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { requireEntity } from '../../common/utils/service-errors.util';
import { CreateStaffMemberDto } from './dto/create-staff-member.dto';
import { UpdateStaffMemberDto } from './dto/update-staff-member.dto';
import { StaffMemberRepository } from './repositories/staff-member.repository';

@Injectable()
export class StaffService {
  constructor(private readonly staff: StaffMemberRepository) {}

  list(restaurantId?: string) {
    return this.staff.findMany({
      where: restaurantId
        ? { restaurantId, isActive: true }
        : { isActive: true },
      order: { createdAt: 'DESC' },
    });
  }

  async create(dto: CreateStaffMemberDto, actorUserId: string) {
    const actor = requireEntity(
      await this.staff.findOne({
        where: { userId: actorUserId, isActive: true },
      }),
      'Staff member not found',
    );
    if (dto.restaurantId !== actor.restaurantId) {
      throw new NotFoundException('Restaurant not found');
    }
    return this.staff.save(this.staff.create({ ...dto, isActive: true }));
  }

  async update(id: string, dto: UpdateStaffMemberDto, actorUserId: string) {
    const actor = requireEntity(
      await this.staff.findOne({
        where: { userId: actorUserId, isActive: true },
      }),
      'Staff member not found',
    );
    const staff = requireEntity(
      await this.staff.findOne({
        where: { id, restaurantId: actor.restaurantId },
      }),
      'Staff member not found',
    );
    Object.assign(staff, dto);
    return this.staff.save(staff);
  }

  async deactivate(id: string, actorUserId: string) {
    const actor = requireEntity(
      await this.staff.findOne({
        where: { userId: actorUserId, isActive: true },
      }),
      'Staff member not found',
    );
    const staff = requireEntity(
      await this.staff.findOne({
        where: { id, restaurantId: actor.restaurantId },
      }),
      'Staff member not found',
    );
    if (staff.userId === actorUserId) {
      throw new BadRequestException(
        'You cannot deactivate your own staff access',
      );
    }
    staff.isActive = false;
    return this.staff.save(staff);
  }
}
