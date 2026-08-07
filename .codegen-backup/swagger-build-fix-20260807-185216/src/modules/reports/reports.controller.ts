import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { SalesReportQueryDto } from './dto/sales-report-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

import { ApiBearerAuth, ApiBody, ApiOperation, ApiParam, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';

@ApiTags('Reports')
@Controller('reports')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(RoleEnum.ADMIN)
export class ReportsController {
  constructor(private readonly service: ReportsService) {}

  @Get('sales')
  @ApiOperation({ summary: 'Sales' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  sales(@Query() query: SalesReportQueryDto) {
    return this.service.sales(query);
  }

  @Get('popular-items')
  @ApiOperation({ summary: 'Popular' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  popular(@Query() query: SalesReportQueryDto) {
    return this.service.popularItems(query);
  }
}
