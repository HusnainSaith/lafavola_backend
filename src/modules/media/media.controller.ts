import {
  Body,
  Controller,
  Delete,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBody,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateUploadUrlDto } from './dto/create-upload-url.dto';
import {
  FinalizeUploadDto,
  UploadAuthorizationResponseDto,
} from './dto/finalize-upload.dto';
import { MediaService } from './media.service';

@ApiTags('Media')
@Controller('media')
@UseGuards(JwtAuthGuard)
export class MediaController {
  constructor(private readonly service: MediaService) {}

  @Post('uploads')
  @ApiOperation({ summary: 'Authorize a short-lived direct S3 upload' })
  @ApiBody({ type: CreateUploadUrlDto })
  @ApiResponse({ status: 201, type: UploadAuthorizationResponseDto })
  authorize(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateUploadUrlDto,
  ) {
    return this.service.authorizeUpload(user.id, dto);
  }

  @Post(':id/finalize')
  @ApiOperation({ summary: 'Verify uploaded S3 metadata and activate media' })
  @ApiParam({ name: 'id', type: String })
  @ApiBody({ type: FinalizeUploadDto })
  finalize(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: FinalizeUploadDto,
  ) {
    return this.service.finalize(user.id, id, dto);
  }

  @Delete(':id')
  @ApiOperation({
    summary: 'Delete an owned media object using its trusted key',
  })
  async remove(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    await this.service.remove(user.id, id);
    return { success: true };
  }
}
