import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RoleEnum } from '../roles/role.enum';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { SalesReportQueryDto } from './dto/sales-report-query.dto';
import { ReportsService } from './reports.service';

import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
@ApiTags('Reports')
@ApiBearerAuth('JWT-auth')
@Controller('reports')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(RoleEnum.ADMIN)
export class ReportsController {
  constructor(private readonly service: ReportsService) {}

  @Get('sales')
  @ApiOperation({ summary: 'Sales' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  sales(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: SalesReportQueryDto,
  ) {
    return this.service.salesForAdmin(user.id, query);
  }

  @Get('daily-revenue')
  @ApiOperation({ summary: 'Daily recognized and net revenue in minor units' })
  @ApiResponse({ status: 200, description: 'Inclusive daily series' })
  daily(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: SalesReportQueryDto,
  ) {
    return this.service.dailyRevenueForAdmin(user.id, query);
  }

  @Get('popular-items')
  @ApiOperation({ summary: 'Popular' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  popular(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: SalesReportQueryDto,
  ) {
    return this.service.popularItemsForAdmin(user.id, query);
  }
}
