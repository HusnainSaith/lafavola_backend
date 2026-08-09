import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class CreateOptionChoiceDto {
  @IsOptional() @IsUUID() ingredientId?: string;
  @IsString() @MaxLength(140) name: string;
  @IsString() @MaxLength(120) code: string;
  @IsOptional() @IsInt() priceAdjustmentMinor?: number;
  @IsOptional() @IsInt() caloriesAdjustment?: number;
  @IsOptional() @IsBoolean() isDefault?: boolean;
  @IsOptional() @IsInt() displayOrder?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
