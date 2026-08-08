import { Body, Controller, Patch } from '@nestjs/common';
import { Roles } from '../../common/decorators/roles.decorator';
import { RoleEnum } from '../roles/role.enum';
import { UpdateRestaurantDto } from './dto/update-restaurant.dto';
import { RestaurantsService } from './restaurants.service';

import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
@ApiTags('Restaurants')
@Controller('restaurants')
export class RestaurantsController {
  constructor(private readonly service: RestaurantsService) {}

  @Patch()
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Update' })
  @ApiBody({ type: UpdateRestaurantDto })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @Roles(RoleEnum.ADMIN)
  update(@Body() dto: UpdateRestaurantDto) {
    return this.service.updateSingleton(dto);
  }
}
