import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateUploadUrlDto {
  @IsOptional()
  @IsUUID()
  restaurantId?: string;

  @IsString()
  @MaxLength(255)
  fileName: string;

  @IsIn(['image/jpeg', 'image/png', 'image/webp'])
  mimeType: string;

  @IsInt()
  @Min(1)
  @Max(5 * 1024 * 1024)
  sizeBytes: number;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  altText?: string;
}
