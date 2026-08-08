import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import { BaseController } from './common/controllers/base.controller';
import { Public } from './common/decorators/public.decorator';

import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
@ApiTags('System')
@Controller()
@Public()
export class AppController extends BaseController {
  constructor(private readonly appService: AppService) {
    super();
  }

  @Get()
  @ApiOperation({ summary: 'Get Hello' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('health')
  @ApiOperation({ summary: 'Process liveness; does not probe providers' })
  health() {
    return this.appService.health();
  }

  @Get('ready')
  @ApiOperation({ summary: 'Readiness based on configuration and PostgreSQL' })
  @ApiResponse({ status: 503, description: 'Essential dependency unavailable' })
  ready() {
    return this.appService.readiness();
  }
}
