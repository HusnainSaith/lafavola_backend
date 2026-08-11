import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBody,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RoleEnum } from '../roles/role.enum';
import { CreateOptionChoiceDto } from './dto/create-option-choice.dto';
import { CreateOptionGroupDto } from './dto/create-option-group.dto';
import { UpdateOptionChoiceDto } from './dto/update-option-choice.dto';
import { UpdateOptionGroupDto } from './dto/update-option-group.dto';
import { OptionGroupsService } from './option-groups.service';

@ApiTags('Option Groups')
@Controller('option-groups')
export class OptionGroupsController {
  constructor(private readonly service: OptionGroupsService) {}

  @Get()
  @ApiOperation({ summary: 'List' })
  @ApiQuery({ name: 'restaurantId', required: false, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  list(@Query('restaurantId') restaurantId?: string) {
    return this.service.list(restaurantId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Detail' })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  detail(@Param('id') id: string) {
    return this.service.detail(id);
  }

  @Post()
  @ApiOperation({ summary: 'Create' })
  @ApiBody({ type: CreateOptionGroupDto })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateOptionGroupDto,
  ) {
    return this.service.create(dto, user.id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update' })
  @ApiBody({ type: UpdateOptionGroupDto })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateOptionGroupDto,
  ) {
    return this.service.update(id, dto, user.id);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Deactivate' })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  deactivate(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.deactivate(id, user.id);
  }

  @Post(':id/choices')
  @ApiOperation({ summary: 'Add Choice' })
  @ApiBody({ type: CreateOptionChoiceDto })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  addChoice(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: CreateOptionChoiceDto,
  ) {
    return this.service.addChoice(id, dto, user.id);
  }

  @Patch(':id/choices/:choiceId')
  @ApiOperation({ summary: 'Update Choice' })
  @ApiBody({ type: UpdateOptionChoiceDto })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiParam({ name: 'choiceId', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  updateChoice(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Param('choiceId') choiceId: string,
    @Body() dto: UpdateOptionChoiceDto,
  ) {
    return this.service.updateChoice(id, choiceId, dto, user.id);
  }

  @Delete(':id/choices/:choiceId')
  @ApiOperation({ summary: 'Deactivate Choice' })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiParam({ name: 'choiceId', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  deactivateChoice(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Param('choiceId') choiceId: string,
  ) {
    return this.service.deactivateChoice(id, choiceId, user.id);
  }
}
