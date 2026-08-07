import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CartsService } from './carts.service';
import { AddCartItemDto } from './dto/add-cart-item.dto';
import { UpdateCartItemDto } from './dto/update-cart-item.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';

@Controller('cart')
@UseGuards(JwtAuthGuard)
export class CartsController {
  constructor(private readonly service: CartsService) {}

  @Get()
  detail(
    @CurrentUser() user: AuthenticatedUser,
    @Query('restaurantId') restaurantId: string,
  ) {
    return this.service.detail(user.id, restaurantId);
  }

  @Post('items')
  add(
    @CurrentUser() user: AuthenticatedUser,
    @Query('restaurantId') restaurantId: string,
    @Body() dto: AddCartItemDto,
  ) {
    return this.service.addItem(user.id, restaurantId, dto);
  }

  @Patch('items/:id')
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateCartItemDto,
  ) {
    return this.service.updateItem(user.id, id, dto);
  }

  @Delete('items/:id')
  async remove(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    await this.service.removeItem(user.id, id);
    return { success: true };
  }
}
