import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';
import { PizzaSizeCode } from '../enums/pizza-size-code.enum';

export class CreateMenuItemSizeDto {
  @IsEnum(PizzaSizeCode) sizeCode: PizzaSizeCode;
  @IsString() @MaxLength(80) displayName: string;
  @IsInt() @Min(0) basePriceMinor: number;
  @IsOptional() @IsInt() @Min(0) calories?: number;
  @IsOptional() @IsInt() @Min(0) displayOrder?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
