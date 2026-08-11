import { Body, Controller, Get, Patch, Put, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RoleEnum } from '../roles/role.enum';
import { UpsertBusinessHoursDto } from './dto/upsert-business-hours.dto';
import { UpdateRestaurantDto } from './dto/update-restaurant.dto';
import { RestaurantsService } from './restaurants.service';

@ApiTags('Restaurants')
@Controller('restaurants')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(RoleEnum.ADMIN)
export class RestaurantsController {
  constructor(private readonly service: RestaurantsService) {}

  @Get()
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get the configured restaurant' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  getSingleton(@CurrentUser() user: AuthenticatedUser) {
    return this.service.getSingleton(user.id);
  }

  @Get('hours')
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'List the configured restaurant business hours' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  listBusinessHours(@CurrentUser() user: AuthenticatedUser) {
    return this.service.listBusinessHours(user.id);
  }

  @Put('hours')
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Create or replace business hours for a weekday' })
  @ApiBody({ type: UpsertBusinessHoursDto })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  upsertBusinessHours(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpsertBusinessHoursDto,
  ) {
    return this.service.upsertBusinessHours(dto, user.id);
  }

  @Patch()
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Update' })
  @ApiBody({ type: UpdateRestaurantDto })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateRestaurantDto,
  ) {
    return this.service.updateSingleton(dto, user.id);
  }
}
