import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
} from '@nestjs/common';
import { RolesService } from './roles.service';
import { CreateRoleDto } from './dto/create-role.dto';
import { UpdateRoleDto } from './dto/update-role.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Permissions } from '../../common/decorators/permissions.decorator';
import { RoleEnum } from './role.enum';
import { SecurityUtil } from '../../common/utils/security.util';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { BaseController } from '../../common/controllers/base.controller';

@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@ApiTags('Roles')
@Controller('roles')
export class RolesController extends BaseController {
  constructor(private readonly rolesService: RolesService) {
    super();
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Create a new role' })
  @Roles(RoleEnum.ADMIN)
  @Permissions('roles.create')
  create(@Body() dto: CreateRoleDto) {
    return this.handleAsyncOperation(this.rolesService.create(dto));
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Retrieve all roles' })
  @Roles(RoleEnum.ADMIN)
  @Permissions('roles.read')
  findAll() {
    return this.handleAsyncOperation(this.rolesService.findAll());
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Retrieve a role by ID' })
  @Permissions('roles.read')
  @Roles(RoleEnum.ADMIN)
  findOne(@Param('id') id: string) {
    const validId = SecurityUtil.validateId(id);
    return this.handleAsyncOperation(this.rolesService.findOne(validId));
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Update a role by ID' })
  @Roles(RoleEnum.ADMIN)
  @Permissions('roles.update')
  update(@Param('id') id: string, @Body() dto: UpdateRoleDto) {
    const validId = SecurityUtil.validateId(id);
    return this.handleAsyncOperation(this.rolesService.update(validId, dto));
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Remove a role by ID' })
  @Roles(RoleEnum.ADMIN)
  @Permissions('roles.delete')
  remove(@Param('id') id: string) {
    const validId = SecurityUtil.validateId(id);
    return this.handleAsyncOperation(this.rolesService.remove(validId));
  }
}
