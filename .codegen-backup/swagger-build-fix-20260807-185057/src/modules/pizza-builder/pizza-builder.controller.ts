import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { PizzaBuilderService } from './pizza-builder.service';
import { BuildPizzaDto } from './dto/build-pizza.dto';

@Controller('pizza-builder')
export class PizzaBuilderController {
  constructor(private readonly service: PizzaBuilderService) {}

  @Get(':menuItemId')
  configuration(@Param('menuItemId') menuItemId: string) {
    return this.service.getRule(menuItemId);
  }

  @Post('build')
  build(@Body() dto: BuildPizzaDto) {
    return this.service.build(dto);
  }
}
