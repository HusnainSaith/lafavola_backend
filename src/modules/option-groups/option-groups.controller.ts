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

import { ApiBearerAuth, ApiBody, ApiOperation, ApiParam, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
@ApiTags('Option Groups')
@Controller('option-groups')
export class OptionGroupsController {
  constructor(private readonly service: OptionGroupsService) {}

  @Get()
  @ApiOperation({ summary: 'List' })
  @ApiQuery({ name: 'restaurantId', required: false, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  list(@Query('restaurantId') restaurantId?: string) {
    return this.service.list(restaurantId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Detail' })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  detail(@Param('id') id: string) {
    return this.service.detail(id);
  }

  @Post()
  @ApiOperation({ summary: 'Create' })
  @ApiBody({ type: CreateOptionGroupDto })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  create(@Body() dto: CreateOptionGroupDto) {
    return this.service.create(dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update' })
  @ApiBody({ type: UpdateOptionGroupDto })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdateOptionGroupDto) {
    return this.service.update(id, dto);
  }

  @Post(':id/choices')
  @ApiOperation({ summary: 'Add Choice' })
  @ApiBody({ type: CreateOptionChoiceDto })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  addChoice(@Param('id') id: string, @Body() dto: CreateOptionChoiceDto) {
    return this.service.addChoice(id, dto);
  }
}
