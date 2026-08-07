import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Query,
} from '@nestjs/common';
import { PermissionsService } from './permissions.service';
import { CreatePermissionDto } from './dto/create-permission.dto';
import { UpdatePermissionDto } from './dto/update-permission.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Permissions } from '../../common/decorators/permissions.decorator';
import { RoleEnum } from '../roles/role.enum';
import { SecurityUtil } from '../../common/utils/security.util';
import { ApiBearerAuth, ApiBody, ApiOperation, ApiParam, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { BaseController } from '../../common/controllers/base.controller';

@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@ApiTags('permissions')
@Controller('permissions')
export class PermissionsController extends BaseController {
  constructor(private readonly permissionsService: PermissionsService) {
    super();
  }

  @Post()
  @ApiOperation({ summary: 'Use Guards' })
  @ApiBody({ type: CreatePermissionDto })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  // @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Create a new permission' })
  @Roles(RoleEnum.ADMIN)
  @Permissions('permissions.create')
  create(@Body() dto: CreatePermissionDto) {
    return this.handleAsyncOperation(this.permissionsService.create(dto));
  }

  @Get()
  @ApiOperation({ summary: 'Use Guards' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  // @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @Permissions('permissions.read')
  @ApiOperation({ summary: 'Retrieve all permissions' })
  findAll() {
    return this.handleAsyncOperation(this.permissionsService.findAll());
  }

  @Get('resources')
  @ApiOperation({ summary: 'Use Guards' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  // @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Retrieve all resources' })
  @Permissions('permissions.read')
  getAllResources() {
    return this.handleAsyncOperation(this.permissionsService.getAllResources());
  }

  @Get('actions')
  @ApiOperation({ summary: 'Use Guards' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  // @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Retrieve all actions' })
  @Permissions('permissions.read')
  getAllActions() {
    return this.handleAsyncOperation(this.permissionsService.getAllActions());
  }

  @Get('by-resource')
  @ApiOperation({ summary: 'Use Guards' })
  @ApiQuery({ name: 'resource', required: false, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  // @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @Permissions('permissions.read')
  @ApiOperation({ summary: 'Retrieve all permissions by resource' })
  findByResource(@Query('resource') resource: string) {
    return this.handleAsyncOperation(
      this.permissionsService.findByResource(resource),
    );
  }

  @Get(':id')
  @ApiOperation({ summary: 'Use Guards' })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  // @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @Permissions('permissions.read')
  @ApiOperation({ summary: 'Retrieve a specific permission' })
  findOne(@Param('id') id: string) {
    const validId = SecurityUtil.validateId(id);
    return this.handleAsyncOperation(this.permissionsService.findOne(validId));
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Use Guards' })
  @ApiBody({ type: UpdatePermissionDto })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  // @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @Permissions('permission.update')
  @ApiOperation({ summary: 'Update a specific permission' })
  @Roles(RoleEnum.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdatePermissionDto) {
    const validId = SecurityUtil.validateId(id);
    return this.handleAsyncOperation(
      this.permissionsService.update(validId, dto),
    );
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Use Guards' })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  // @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @Permissions('permissions.delete')
  @ApiOperation({ summary: 'Delete a specific permission' })
  @Roles(RoleEnum.ADMIN)
  remove(@Param('id') id: string) {
    const validId = SecurityUtil.validateId(id);
    return this.handleAsyncOperation(this.permissionsService.remove(validId));
  }
}
