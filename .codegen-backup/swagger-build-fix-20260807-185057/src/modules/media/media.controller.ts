import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { MediaService } from './media.service';
import { CreateUploadUrlDto } from './dto/create-upload-url.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';

@Controller('media')
@UseGuards(JwtAuthGuard)
export class MediaController {
  constructor(private readonly service: MediaService) {}

  @Post('uploads')
  register(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateUploadUrlDto,
  ) {
    return this.service.registerPendingUpload(user.id, dto);
  }
}
