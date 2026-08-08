import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';

export enum MediaPurpose {
  MENU_IMAGE = 'menu_image',
  AVATAR = 'avatar',
  SUPPORT_ATTACHMENT = 'support_attachment',
}

export class CreateUploadUrlDto {
  @ApiProperty({ enum: MediaPurpose })
  @IsEnum(MediaPurpose)
  purpose: MediaPurpose;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  restaurantId?: string;

  @ApiPropertyOptional({ description: 'Menu item or support ticket UUID' })
  @IsOptional()
  @IsUUID()
  targetId?: string;

  @ApiProperty()
  @IsString()
  @MaxLength(255)
  fileName: string;

  @ApiProperty()
  @IsString()
  @MaxLength(120)
  mimeType: string;

  @ApiProperty({ maximum: 10485760 })
  @IsInt()
  @Min(1)
  sizeBytes: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(255)
  altText?: string;
}
