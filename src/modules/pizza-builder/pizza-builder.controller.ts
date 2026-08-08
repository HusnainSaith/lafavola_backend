import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { BuildPizzaDto } from './dto/build-pizza.dto';
import { PizzaBuilderService } from './pizza-builder.service';

import {
  ApiBody,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
@ApiTags('Pizza Builder')
@Controller('pizza-builder')
export class PizzaBuilderController {
  constructor(private readonly service: PizzaBuilderService) {}

  @Get(':menuItemId')
  @ApiOperation({ summary: 'Configuration' })
  @ApiParam({ name: 'menuItemId', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  configuration(@Param('menuItemId') menuItemId: string) {
    return this.service.getRule(menuItemId);
  }

  @Post('build')
  @ApiOperation({ summary: 'Build' })
  @ApiBody({ type: BuildPizzaDto })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  build(@Body() dto: BuildPizzaDto) {
    return this.service.build(dto);
  }
}
