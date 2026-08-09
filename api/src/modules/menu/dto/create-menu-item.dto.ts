import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { MenuItemType } from '../enums/menu-item-type.enum';
import { CreateMenuItemSizeDto } from './create-menu-item-size.dto';

export class CreateMenuItemDto {
  @IsUUID() restaurantId: string;
  @IsOptional() @IsUUID() categoryId?: string;
  @IsString() @MaxLength(180) name: string;
  @IsString() @MaxLength(200) slug: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsUUID() imageAssetId?: string;
  @IsEnum(MenuItemType) itemType: MenuItemType;
  @IsOptional() @IsInt() @Min(0) calories?: number;
  @IsOptional() @IsInt() @Min(0) preparationMinutes?: number;
  @IsOptional() @IsBoolean() isVegetarian?: boolean;
  @IsOptional() @IsBoolean() isVegan?: boolean;
  @IsOptional() @IsBoolean() isGlutenFree?: boolean;
  @IsOptional() @IsBoolean() isSpicy?: boolean;
  @IsOptional() @IsBoolean() isPopular?: boolean;
  @IsOptional() @IsBoolean() isActive?: boolean;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateMenuItemSizeDto)
  sizes: CreateMenuItemSizeDto[];
}
