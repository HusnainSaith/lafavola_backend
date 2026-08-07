import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { StaffService } from './staff.service';
import { CreateStaffMemberDto } from './dto/create-staff-member.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('staff')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(RoleEnum.ADMIN)
export class StaffController {
  constructor(private readonly service: StaffService) {}

  @Get()
  list(@Query('restaurantId') restaurantId?: string) {
    return this.service.list(restaurantId);
  }

  @Post()
  create(@Body() dto: CreateStaffMemberDto) {
    return this.service.create(dto);
  }

  @Delete(':id')
  deactivate(@Param('id') id: string) {
    return this.service.deactivate(id);
  }
}
