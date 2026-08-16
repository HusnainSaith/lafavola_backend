import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
} from '@nestjs/common';
import { BuildPizzaDto } from './dto/build-pizza.dto';
import { Delete, Patch, UseGuards } from '@nestjs/common';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RoleEnum } from '../roles/role.enum';
import { Public } from '../../common/decorators/public.decorator';
import {
  CreatePizzaBuilderRuleDto,
  UpdatePizzaBuilderRuleDto,
} from './dto/manage-pizza-builder-rule.dto';
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

  @Get('admin/rules')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  @ApiOperation({ summary: 'List restaurant pizza-builder rules' })
  listAdmin(@CurrentUser() user: AuthenticatedUser) {
    return this.service.listAdmin(user.id);
  }

  @Post('admin/rules')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  @ApiOperation({ summary: 'Create a restaurant pizza-builder rule' })
  createAdmin(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreatePizzaBuilderRuleDto,
  ) {
    return this.service.createAdmin(user.id, dto);
  }

  @Patch('admin/rules/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  @ApiOperation({ summary: 'Update a restaurant pizza-builder rule' })
  updateAdmin(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
    @Body() dto: UpdatePizzaBuilderRuleDto,
  ) {
    return this.service.updateAdmin(user.id, id, dto);
  }

  @Delete('admin/rules/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleEnum.ADMIN)
  @ApiOperation({ summary: 'Deactivate a restaurant pizza-builder rule' })
  deactivateAdmin(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    return this.service.deactivateAdmin(user.id, id);
  }

  @Get(':menuItemId')
  @Public()
  @ApiOperation({ summary: 'Configuration' })
  @ApiParam({ name: 'menuItemId', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  configuration(
    @Param('menuItemId', new ParseUUIDPipe({ version: '4' }))
    menuItemId: string,
  ) {
    return this.service.getConfiguration(menuItemId);
  }

  @Post('build')
  @Public()
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
