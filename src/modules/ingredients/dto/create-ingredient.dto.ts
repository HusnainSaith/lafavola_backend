import {
  IsArray,
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateIngredientDto {
  @IsUUID() restaurantId: string;
  @IsOptional() @IsUUID() categoryId?: string;
  @IsString() @MaxLength(140) name: string;
  @IsString() @MaxLength(160) slug: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsUUID() imageAssetId?: string;
  @IsOptional() @IsInt() @Min(0) extraPriceMinor?: number;
  @IsOptional() @IsInt() @Min(0) calories?: number;
  @IsOptional() @IsBoolean() isVegetarian?: boolean;
  @IsOptional() @IsBoolean() isVegan?: boolean;
  @IsOptional() @IsBoolean() isGlutenFree?: boolean;
  @IsOptional() @IsBoolean() isSpicy?: boolean;
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  containsAllergens?: string[];
  @IsOptional() @IsBoolean() isActive?: boolean;
}
