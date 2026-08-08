import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateStaffMemberDto } from './dto/create-staff-member.dto';
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

  create(dto: CreateStaffMemberDto) {
    return this.staff.save(this.staff.create({ ...dto, isActive: true }));
  }

  async deactivate(id: string) {
    const staff = await this.staff.findById(id);
    if (!staff) throw new NotFoundException('Staff member not found');
    staff.isActive = false;
    return this.staff.save(staff);
  }
}
