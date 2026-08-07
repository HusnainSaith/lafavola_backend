import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { DeliveriesService } from './deliveries.service';
import { AssignDriverDto } from './dto/assign-driver.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('deliveries')
export class DeliveriesController {
  constructor(private readonly service: DeliveriesService) {}

  @Get('orders/:orderId/tracking')
  @UseGuards(JwtAuthGuard)
  tracking(@Param('orderId') orderId: string) {
    return this.service.getTracking(orderId);
  }

  @Post('orders/:orderId/assign')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  assign(
    @CurrentUser() user: AuthenticatedUser,
    @Param('orderId') orderId: string,
    @Body() dto: AssignDriverDto,
  ) {
    return this.service.assign(orderId, user.id, dto);
  }

  @Patch('orders/:orderId/location')
  @UseGuards(JwtAuthGuard)
  updateLocation(
    @Param('orderId') orderId: string,
    @Body() dto: UpdateLocationDto,
  ) {
    return this.service.updateLocation(orderId, dto);
  }
}
