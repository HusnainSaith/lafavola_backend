import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RoleEnum } from '../roles/role.enum';
import { DeliveriesService } from './deliveries.service';
import { AssignDriverDto } from './dto/assign-driver.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { UpdateDeliveryStatusDto } from './dto/update-delivery-status.dto';

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
    return this.service.getTracking(user.id, orderId);
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
    return this.service.assignmentForDriver(
      user.id,
      orderId,
      typeof user.role === 'object' && user.role?.name === RoleEnum.ADMIN,
    );
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
    return this.service.transition(
      orderId,
      dto.status,
      user.id,
      typeof user.role === 'object' && user.role?.name === RoleEnum.ADMIN,
    );
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
    return this.service.updateLocation(
      orderId,
      dto,
      user.id,
      typeof user.role === 'object' && user.role?.name === RoleEnum.ADMIN,
    );
  }
}
