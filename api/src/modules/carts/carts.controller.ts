import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CartsService } from './carts.service';
import { AddCartItemDto } from './dto/add-cart-item.dto';
import { UpdateCartItemDto } from './dto/update-cart-item.dto';

import {
  ApiBody,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
@ApiTags('Carts')
@Controller('cart')
@UseGuards(JwtAuthGuard)
export class CartsController {
  constructor(private readonly service: CartsService) {}

  @Get()
  @ApiOperation({ summary: 'Detail' })
  @ApiQuery({
    name: 'restaurantId',
    required: false,
    schema: { type: 'string', format: 'uuid' },
    description:
      'Restaurant whose active cart should be returned; defaults to the active restaurant',
  })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  detail(
    @CurrentUser() user: AuthenticatedUser,
    @Query(
      'restaurantId',
      new ParseUUIDPipe({ version: '4', optional: true }),
    )
    restaurantId?: string,
  ) {
    return this.service.detail(user.id, restaurantId);
  }

  @Post('items')
  @ApiOperation({ summary: 'Add' })
  @ApiBody({ type: AddCartItemDto })
  @ApiQuery({
    name: 'restaurantId',
    required: false,
    schema: { type: 'string', format: 'uuid' },
    description:
      'Restaurant that owns the menu item and cart; defaults to the active restaurant',
  })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  add(
    @CurrentUser() user: AuthenticatedUser,
    @Query(
      'restaurantId',
      new ParseUUIDPipe({ version: '4', optional: true }),
    )
    restaurantId: string | undefined,
    @Body() dto: AddCartItemDto,
  ) {
    return this.service.addItem(user.id, restaurantId, dto);
  }

  @Patch('items/:id')
  @ApiOperation({ summary: 'Update' })
  @ApiBody({ type: UpdateCartItemDto })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateCartItemDto,
  ) {
    return this.service.updateItem(user.id, id, dto);
  }

  @Delete('items/:id')
  @ApiOperation({ summary: 'Remove' })
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async remove(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    await this.service.removeItem(user.id, id);
    return { success: true };
  }

  @Delete()
  @ApiOperation({ summary: 'Clear the authenticated customer cart' })
  @ApiQuery({
    name: 'restaurantId',
    required: false,
    schema: { type: 'string', format: 'uuid' },
  })
  async clear(
    @CurrentUser() user: AuthenticatedUser,
    @Query(
      'restaurantId',
      new ParseUUIDPipe({ version: '4', optional: true }),
    )
    restaurantId?: string,
  ) {
    await this.service.clear(user.id, restaurantId);
    return { success: true };
  }
}
