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
import { Roles } from '../../common/decorators/roles.decorator';
import { AdminListQueryDto } from '../../common/dto/admin-list-query.dto';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RoleEnum } from '../roles/role.enum';
import { DeliveriesService } from './deliveries.service';
import { AssignDriverDto } from './dto/assign-driver.dto';
import { CreateDriverDto } from './dto/create-driver.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { UpdateDeliveryStatusDto } from './dto/update-delivery-status.dto';
import { UpdateDriverDto } from './dto/update-driver.dto';

import {
  ApiBody,
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
@ApiTags('Deliveries')
@ApiBearerAuth('JWT-auth')
@Controller('deliveries')
export class DeliveriesController {
  constructor(private readonly service: DeliveriesService) {}

  @Get('admin')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  @ApiOperation({
    summary: 'List delivery assignments for the active restaurant',
  })
  @ApiResponse({ status: 200, description: 'Paginated delivery board' })
  adminList(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: AdminListQueryDto,
  ) {
    return this.service.listAdmin(user.id, query);
  }

  @Get('admin/dispatch-board')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  @ApiOperation({ summary: 'List delivery orders available to dispatch' })
  @ApiResponse({ status: 200, description: 'Restaurant dispatch board' })
  dispatchBoard(@CurrentUser() user: AuthenticatedUser) {
    return this.service.dispatchBoard(user.id);
  }

  @Get('drivers')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  @ApiOperation({ summary: 'List La Favola delivery drivers' })
  @ApiResponse({ status: 200, description: 'Driver directory' })
  drivers(@CurrentUser() user: AuthenticatedUser) {
    return this.service.listDrivers(user.id);
  }

  @Post('drivers')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  @ApiOperation({ summary: 'Create a driver account and staff profile' })
  @ApiBody({ type: CreateDriverDto })
  @ApiResponse({ status: 201, description: 'Driver created' })
  createDriver(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateDriverDto,
  ) {
    return this.service.createDriver(user.id, dto);
  }

  @Patch('drivers/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  @ApiOperation({ summary: 'Update a driver account and staff profile' })
  @ApiParam({ name: 'id', description: 'Staff member ID' })
  @ApiBody({ type: UpdateDriverDto })
  @ApiResponse({ status: 200, description: 'Driver updated' })
  updateDriver(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateDriverDto,
  ) {
    return this.service.updateDriver(user.id, id, dto);
  }

  @Delete('drivers/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  @ApiOperation({ summary: 'Deactivate a driver account' })
  @ApiParam({ name: 'id', description: 'Staff member ID' })
  @ApiResponse({ status: 200, description: 'Driver deactivated' })
  deactivateDriver(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.service.deactivateDriver(user.id, id);
  }

  @Get('orders/:orderId/tracking')
  @ApiOperation({ summary: 'Tracking' })
  @ApiParam({ name: 'orderId', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard)
  tracking(
    @CurrentUser() user: AuthenticatedUser,
    @Param('orderId') orderId: string,
  ) {
    return this.service.getTracking(user.id, orderId, isAdmin(user));
  }

  @Post('orders/:orderId/assign')
  @ApiOperation({ summary: 'Assign' })
  @ApiBody({ type: AssignDriverDto })
  @ApiParam({ name: 'orderId', required: true, type: String })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  assign(
    @CurrentUser() user: AuthenticatedUser,
    @Param('orderId') orderId: string,
    @Body() dto: AssignDriverDto,
  ) {
    return this.service.assign(orderId, user.id, dto);
  }

  @Get('orders/:orderId/assignment')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN, RoleEnum.EMPLOYEE)
  @ApiOperation({ summary: 'Get the assigned driver delivery record' })
  @ApiParam({ name: 'orderId', type: String })
  @ApiResponse({ status: 200, description: 'Assigned delivery' })
  @ApiResponse({ status: 404, description: 'Assignment not found' })
  assignment(
    @CurrentUser() user: AuthenticatedUser,
    @Param('orderId') orderId: string,
  ) {
    return this.service.assignmentForDriver(user.id, orderId, isAdmin(user));
  }

  @Patch('orders/:orderId/status')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN, RoleEnum.EMPLOYEE)
  @ApiOperation({ summary: 'Advance an assigned delivery state' })
  @ApiParam({ name: 'orderId', type: String })
  @ApiBody({ type: UpdateDeliveryStatusDto })
  @ApiResponse({ status: 200, description: 'Delivery state updated' })
  @ApiResponse({ status: 403, description: 'Driver/admin role required' })
  @ApiResponse({ status: 404, description: 'Assignment not found' })
  @ApiResponse({ status: 409, description: 'Invalid state transition' })
  transition(
    @CurrentUser() user: AuthenticatedUser,
    @Param('orderId') orderId: string,
    @Body() dto: UpdateDeliveryStatusDto,
  ) {
    return this.service.transition(orderId, dto.status, user.id, isAdmin(user));
  }

  @Patch('orders/:orderId/location')
  @ApiOperation({ summary: 'Update Location' })
  @ApiBody({ type: UpdateLocationDto })
  @ApiParam({ name: 'orderId', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN, RoleEnum.EMPLOYEE)
  updateLocation(
    @CurrentUser() user: AuthenticatedUser,
    @Param('orderId') orderId: string,
    @Body() dto: UpdateLocationDto,
  ) {
    return this.service.updateLocation(orderId, dto, user.id, isAdmin(user));
  }
}

function isAdmin(user: AuthenticatedUser): boolean {
  return typeof user.role === 'string'
    ? user.role === RoleEnum.ADMIN
    : user.role?.name === RoleEnum.ADMIN;
}
