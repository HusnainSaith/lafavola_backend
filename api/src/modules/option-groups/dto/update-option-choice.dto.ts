import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

/** Lifecycle is handled only by the explicit safety-deactivation route. */
export class UpdateOptionChoiceDto {
  @IsOptional() @IsUUID() ingredientId?: string;
  @IsOptional() @IsString() @MaxLength(140) name?: string;
  @IsOptional() @IsString() @MaxLength(120) code?: string;
  @IsOptional() @IsInt() priceAdjustmentMinor?: number;
  @IsOptional() @IsInt() caloriesAdjustment?: number;
  @IsOptional() @IsBoolean() isDefault?: boolean;
  @IsOptional() @IsInt() displayOrder?: number;
}
