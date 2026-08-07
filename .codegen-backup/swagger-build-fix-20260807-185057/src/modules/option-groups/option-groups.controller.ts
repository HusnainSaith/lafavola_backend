import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { OptionGroupsService } from './option-groups.service';
import { CreateOptionGroupDto } from './dto/create-option-group.dto';
import { UpdateOptionGroupDto } from './dto/update-option-group.dto';
import { CreateOptionChoiceDto } from './dto/create-option-choice.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('option-groups')
export class OptionGroupsController {
  constructor(private readonly service: OptionGroupsService) {}

  @Get()
  list(@Query('restaurantId') restaurantId?: string) {
    return this.service.list(restaurantId);
  }

  @Get(':id')
  detail(@Param('id') id: string) {
    return this.service.detail(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  create(@Body() dto: CreateOptionGroupDto) {
    return this.service.create(dto);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdateOptionGroupDto) {
    return this.service.update(id, dto);
  }

  @Post(':id/choices')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  addChoice(@Param('id') id: string, @Body() dto: CreateOptionChoiceDto) {
    return this.service.addChoice(id, dto);
  }
}
