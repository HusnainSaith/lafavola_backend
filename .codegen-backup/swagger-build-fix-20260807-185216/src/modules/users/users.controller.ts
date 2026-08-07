import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Patch,
  Delete,
  UseGuards,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { CreateUserWithPermissionsDto } from './dto/create-user-with-permissions.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { AssignPermissionsDto } from './dto/assign-permissions.dto';
import { RolesGuard } from '../../common/guards/roles.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Permissions } from '../../common/decorators/permissions.decorator';
import { SecurityUtil } from '../../common/utils/security.util';
import { ApiBearerAuth, ApiBody, ApiOperation, ApiParam, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { BaseController } from '../../common/controllers/base.controller';

@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@ApiTags('Users')
@Controller('users')
export class UsersController extends BaseController {
  constructor(private readonly usersService: UsersService) {
    super();
  }

  @Post()
  @ApiBody({ type: CreateUserDto })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'create users' })
  @Permissions('users.create')
  create(@Body() dto: CreateUserDto) {
    return this.handleAsyncOperation(this.usersService.create(dto));
  }

  @Post('with-permissions')
  @ApiBody({ type: CreateUserWithPermissionsDto })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'create user with permissions' })
  @Permissions('users.create')
  createWithPermissions(@Body() dto: CreateUserWithPermissionsDto) {
    return this.handleAsyncOperation(
      this.usersService.createWithPermissions(dto),
    );
  }

  @Post(':id/permissions')
  @ApiBody({ type: AssignPermissionsDto })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'assign permissions to user by id' })
  @Permissions('users.update')
  assignPermissions(
    @Param('id') id: string,
    @Body() dto: AssignPermissionsDto,
  ) {
    const validId = SecurityUtil.validateId(id);
    return this.handleAsyncOperation(
      this.usersService.assignPermissions(validId, dto),
    );
  }

  @Get(':id/permissions')
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'get user permissions by id' })
  @Permissions('users.read')
  getUserPermissions(@Param('id') id: string) {
    const validId = SecurityUtil.validateId(id);
    return this.handleAsyncOperation(
      this.usersService.getUserPermissions(validId),
    );
  }
  @Get('available-features')
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'get all features' })
  @Permissions('users.read')
  getAvailableFeatures() {
    return this.handleAsyncOperation(this.usersService.getAvailableFeatures());
  }

  // Get available actions for a specific feature
  @Get('available-features/:feature/actions')
  @ApiParam({ name: 'feature', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get permidssion of any feature' })
  @Permissions('users.read')
  getAvailableActionsForFeature(@Param('feature') feature: string) {
    return this.handleAsyncOperation(
      this.usersService.getAvailableActionsForFeature(feature),
    );
  }

  @Get()
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get users' })
  @Permissions('users.read')
  findAll() {
    return this.handleAsyncOperation(this.usersService.findAll());
  }

  @Get(':id')
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'get user by id' })
  @Permissions('users.read')
  findOne(@Param('id') id: string) {
    const validId = SecurityUtil.validateId(id);
    return this.handleAsyncOperation(this.usersService.findOne(validId));
  }

  @Patch(':id')
  @ApiBody({ type: UpdateUserDto })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'update user by id' })
  @Permissions('users.update')
  update(@Param('id') id: string, @Body() dto: UpdateUserDto) {
    const validId = SecurityUtil.validateId(id);
    return this.handleAsyncOperation(this.usersService.update(validId, dto));
  }

  @Delete(':id')
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'delete user by id' })
  @Permissions('users.delete')
  remove(@Param('id') id: string) {
    const validId = SecurityUtil.validateId(id);
    return this.handleAsyncOperation(this.usersService.remove(validId));
  }

  //   @Get('profile')
  // @UseGuards(JwtAuthGuard)
  // async getUserProfile(@Request() req: any) {
  //   const userId = req.user?.id;
  //   const user = await this.usersService.findOneWithPermissions(userId);
  //   if (!user) {
  //     throw new NotFoundException('User not found');
  //   }
  //   return {
  //     success: true,
  //     message: 'User profile retrieved successfully',
  //     data: user,
  //   };
  // }
}
