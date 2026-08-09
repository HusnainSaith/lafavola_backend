import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateCategoryDto {
  @IsUUID() restaurantId: string;
  @IsString() @MaxLength(120) name: string;
  @IsString() @MaxLength(140) slug: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsUUID() imageAssetId?: string;
  @IsOptional() @IsInt() @Min(0) displayOrder?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
