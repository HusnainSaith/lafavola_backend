import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import {
  Delete,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CustomersService } from './customers.service';
import { UpdateCustomerPreferencesDto } from './dto/update-customer-preferences.dto';
import { UpdateCustomerProfileDto } from './dto/update-customer-profile.dto';
import { ApiBearerAuth, ApiParam } from '@nestjs/swagger';
import { CustomerSecuritySessionResponseDto } from './dto/customer-security-session-response.dto';
import { UploadProfilePhotoDto } from './dto/upload-profile-photo.dto';
import { MediaPurpose } from '../media/dto/create-upload-url.dto';
import { MediaService } from '../media/media.service';

import {
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
@ApiTags('Customer App - Profile')
@ApiBearerAuth('JWT-auth')
@Controller('customers/me')
@UseGuards(JwtAuthGuard)
export class CustomersController {
  constructor(
    private readonly service: CustomersService,
    private readonly media: MediaService,
  ) {}

  @Get('profile')
  @ApiOperation({ summary: 'Profile' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  profile(@CurrentUser() user: AuthenticatedUser) {
    return this.service.profile(user.id);
  }

  @Patch('profile')
  @ApiOperation({ summary: 'Update Profile' })
  @ApiBody({ type: UpdateCustomerProfileDto })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  updateProfile(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateCustomerProfileDto,
  ) {
    return this.service.updateProfile(user.id, dto);
  }

  @Post('profile/avatar')
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: 5 * 1024 * 1024 } }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload Profile Photo' })
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file'],
      properties: {
        file: {
          type: 'string',
          format: 'binary',
          description: 'JPEG, PNG, or WebP image (maximum 5 MB)',
        },
        altText: { type: 'string', maxLength: 255 },
      },
    },
  })
  @ApiResponse({ status: 201, description: 'Profile photo uploaded' })
  @ApiResponse({ status: 400, description: 'Invalid or missing image file' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async uploadProfilePhoto(
    @CurrentUser() user: AuthenticatedUser,
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: UploadProfilePhotoDto,
  ) {
    await this.media.upload(user.id, file, {
      purpose: MediaPurpose.AVATAR,
      altText: dto.altText,
    });
    return this.service.profile(user.id);
  }

  @Get('preferences')
  @ApiOperation({ summary: 'Preferences' })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  preferences(@CurrentUser() user: AuthenticatedUser) {
    return this.service.preferences(user.id);
  }

  @Patch('preferences')
  @ApiOperation({ summary: 'Update Preferences' })
  @ApiBody({ type: UpdateCustomerPreferencesDto })
  @ApiResponse({ status: 200, description: 'Successful response' })
  @ApiResponse({
    status: 400,
    description: 'Validation or business-rule error',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  updatePreferences(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateCustomerPreferencesDto,
  ) {
    return this.service.updatePreferences(user.id, dto);
  }

  @Get('security/sessions')
  @ApiOperation({ summary: 'List refresh sessions owned by the customer' })
  @ApiResponse({
    status: 200,
    type: CustomerSecuritySessionResponseDto,
    isArray: true,
  })
  securitySessions(@CurrentUser() user: AuthenticatedUser) {
    return this.service.securitySessions(user.id);
  }

  @Delete('security/sessions/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Revoke an owned refresh session' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiResponse({ status: 204, description: 'Refresh session revoked' })
  @ApiResponse({ status: 404, description: 'Refresh session not found' })
  async revokeSecuritySession(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ): Promise<void> {
    await this.service.revokeSecuritySession(user.id, id);
  }
}
