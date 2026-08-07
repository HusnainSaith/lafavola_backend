import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { MediaService } from './media.service';
import { CreateUploadUrlDto } from './dto/create-upload-url.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';

import { ApiBearerAuth, ApiBody, ApiOperation, ApiParam, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';

@ApiTags('Media')
@Controller('media')
@UseGuards(JwtAuthGuard)
export class MediaController {
  constructor(private readonly service: MediaService) {}

  @Post('uploads')
  @ApiOperation({ summary: 'Register' })
  @ApiBody({ type: CreateUploadUrlDto })
  @ApiResponse({ status: 201, description: 'Successful response' })
  @ApiResponse({ status: 400, description: 'Validation or business-rule error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  register(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateUploadUrlDto,
  ) {
    return this.service.registerPendingUpload(user.id, dto);
  }
}
