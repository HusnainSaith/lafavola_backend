import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBody,
  ApiOperation,
  ApiParam,
  ApiConsumes,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { AdminListQueryDto } from '../../common/dto/admin-list-query.dto';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RoleEnum } from '../roles/role.enum';
import {
  CreateUploadUrlDto,
  MediaPurpose,
  MultipartUploadDto,
} from './dto/create-upload-url.dto';
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

  @Get('admin')
  @UseGuards(RolesGuard)
  @Roles(RoleEnum.ADMIN)
  @ApiOperation({ summary: 'List media for the active staff restaurant' })
  @ApiResponse({ status: 200, description: 'Paginated media library' })
  adminList(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: AdminListQueryDto,
  ) {
    return this.service.listAdmin(user.id, query);
  }

  @Post('upload')
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: 10 * 1024 * 1024 } }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload an image or support file directly to S3' })
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file', 'purpose'],
      properties: {
        file: { type: 'string', format: 'binary' },
        purpose: { type: 'string', enum: Object.values(MediaPurpose) },
        restaurantId: { type: 'string', format: 'uuid' },
        targetId: { type: 'string', format: 'uuid' },
        altText: { type: 'string' },
      },
    },
  })
  upload(
    @CurrentUser() user: AuthenticatedUser,
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: MultipartUploadDto,
  ) {
    return this.service.upload(user.id, file, dto);
  }

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
