import {
  IsArray,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CartItemOptionDto {
  @IsOptional() @IsUUID() optionGroupId?: string;
  @IsOptional() @IsUUID() optionChoiceId?: string;
  @IsOptional() @IsUUID() ingredientId?: string;
  @IsOptional() @IsString() action?: 'add' | 'remove' | 'replace';
  @IsOptional() @Min(0.01) quantity?: number;
}

export class AddCartItemDto {
  @IsUUID() menuItemId: string;
  @IsOptional() @IsUUID() menuItemSizeId?: string;
  @IsInt() @Min(1) quantity: number;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CartItemOptionDto)
  options?: CartItemOptionDto[];

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  specialInstructions?: string;
}
