import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { CustomersService } from './customers.service';
import { UpdateCustomerProfileDto } from './dto/update-customer-profile.dto';
import { UpdateCustomerPreferencesDto } from './dto/update-customer-preferences.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';

@Controller('customers/me')
@UseGuards(JwtAuthGuard)
export class CustomersController {
  constructor(private readonly service: CustomersService) {}

  @Get('profile')
  profile(@CurrentUser() user: AuthenticatedUser) {
    return this.service.profile(user.id);
  }

  @Patch('profile')
  updateProfile(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateCustomerProfileDto,
  ) {
    return this.service.updateProfile(user.id, dto);
  }

  @Get('preferences')
  preferences(@CurrentUser() user: AuthenticatedUser) {
    return this.service.preferences(user.id);
  }

  @Patch('preferences')
  updatePreferences(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateCustomerPreferencesDto,
  ) {
    return this.service.updatePreferences(user.id, dto);
  }
}
