import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { SalesReportQueryDto } from './dto/sales-report-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';

@Controller('reports')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(RoleEnum.ADMIN)
export class ReportsController {
  constructor(private readonly service: ReportsService) {}

  @Get('sales')
  sales(@Query() query: SalesReportQueryDto) {
    return this.service.sales(query);
  }

  @Get('popular-items')
  popular(@Query() query: SalesReportQueryDto) {
    return this.service.popularItems(query);
  }
}
