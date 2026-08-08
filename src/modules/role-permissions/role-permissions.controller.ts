import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { BaseController } from '../../common/controllers/base.controller';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RoleEnum } from '../roles/role.enum';
import { AssignRolePermissionsDto } from './dto/assign-role-permissions.dto';
import { RolePermissionsService } from './role-permissions.service';

@ApiTags('Role Permissions')
@Controller('role-permissions')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(RoleEnum.ADMIN)
export class RolePermissionsController extends BaseController {
  constructor(private readonly rolePermissionsService: RolePermissionsService) {
    super();
  }

  @Post(':roleId')
  @ApiBody({ type: AssignRolePermissionsDto })
  @ApiParam({ name: 'roleId', required: true, type: String })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Assign permissions to a role' })
  assignPermissions(
    @Param('roleId') roleId: string,
    @Body() dto: AssignRolePermissionsDto,
  ) {
    return this.handleAsyncOperation(
      this.rolePermissionsService.assignPermissions(roleId, dto),
    );
  }

  @Get(':roleId')
  @ApiParam({ name: 'roleId', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Retrieve permissions for a role' })
  getPermissions(@Param('roleId') roleId: string) {
    return this.handleAsyncOperation(
      this.rolePermissionsService.getPermissionsByRole(roleId),
    );
  }

  @Delete(':roleId/:permissionId')
  @ApiParam({ name: 'roleId', required: true, type: String })
  @ApiParam({ name: 'permissionId', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Remove a permission from a role' })
  removePermission(
    @Param('roleId') roleId: string,
    @Param('permissionId') permissionId: string,
  ) {
    return this.handleAsyncOperation(
      this.rolePermissionsService.removePermission(roleId, permissionId),
    );
  }
}
