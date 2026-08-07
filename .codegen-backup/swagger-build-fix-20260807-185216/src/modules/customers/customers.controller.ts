import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { CustomersService } from './customers.service';
import { UpdateCustomerProfileDto } from './dto/update-customer-profile.dto';
import { UpdateCustomerPreferencesDto } from './dto/update-customer-preferences.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';

import { ApiBearerAuth, ApiBody, ApiOperation, ApiParam, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';

@ApiTags('Customers')
@Controller('customers/me')
@UseGuards(JwtAuthGuard)
export class CustomersController {
  constructor(private readonly service: CustomersService) {}

  @Get('profile')
  @ApiOperation({ summary: 'Profile' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  profile(@CurrentUser() user: AuthenticatedUser) {
    return this.service.profile(user.id);
  }

  @Patch('profile')
  @ApiOperation({ summary: 'Update Profile' })
  @ApiBody({ type: UpdateCustomerProfileDto })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  updateProfile(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateCustomerProfileDto,
  ) {
    return this.service.updateProfile(user.id, dto);
  }

  @Get('preferences')
  @ApiOperation({ summary: 'Preferences' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  preferences(@CurrentUser() user: AuthenticatedUser) {
    return this.service.preferences(user.id);
  }

  @Patch('preferences')
  @ApiOperation({ summary: 'Update Preferences' })
  @ApiBody({ type: UpdateCustomerPreferencesDto })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  updatePreferences(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateCustomerPreferencesDto,
  ) {
    return this.service.updatePreferences(user.id, dto);
  }
}
