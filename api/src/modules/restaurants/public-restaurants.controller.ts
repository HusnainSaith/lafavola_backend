import { BadRequestException, Controller, Get, Query } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { RestaurantsService } from './restaurants.service';

@ApiTags('Restaurant')
@Controller('restaurant')
export class PublicRestaurantsController {
  constructor(private readonly service: RestaurantsService) {}

  @Get()
  @Public()
  @ApiOperation({
    summary: 'Get the public La Favola location and fulfilment settings',
  })
  @ApiResponse({ status: 200, description: 'Public restaurant configuration' })
  getPublicRestaurant() {
    return this.service.getPublicSingleton();
  }

  @Get('availability')
  @Public()
  @ApiOperation({
    summary: 'List server-authoritative La Favola fulfilment time slots',
  })
  @ApiResponse({ status: 200, description: 'ASAP state and scheduled slots' })
  getAvailability(
    @Query('orderType') orderType = 'delivery',
    @Query('date') date?: string,
    @Query('menuItemId') menuItemId?: string,
  ) {
    if (!['delivery', 'pickup'].includes(orderType)) {
      throw new BadRequestException('orderType must be delivery or pickup');
    }
    if (date && !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      throw new BadRequestException('date must use YYYY-MM-DD');
    }
    if (
      menuItemId &&
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
        menuItemId,
      )
    ) {
      throw new BadRequestException('menuItemId must be a UUID');
    }
    return this.service.getPublicAvailability(
      orderType as 'delivery' | 'pickup',
      date,
      menuItemId,
    );
  }
}
