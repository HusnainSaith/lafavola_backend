import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import { BaseController } from './common/controllers/base.controller';

import { ApiBearerAuth, ApiBody, ApiOperation, ApiParam, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';

@ApiTags('System')
@Controller()
export class AppController extends BaseController {
  constructor(private readonly appService: AppService) {
    super();
  }

  @Get()
  @ApiOperation({ summary: 'Get Hello' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  getHello(): string {
    return this.appService.getHello();
  }
}
