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
import { OptionType } from '../enums/option-type.enum';
import { CreateOptionChoiceDto } from './create-option-choice.dto';

export class CreateOptionGroupDto {
  @IsUUID() restaurantId: string;
  @IsString() @MaxLength(140) name: string;
  @IsString() @MaxLength(100) code: string;
  @IsEnum(OptionType) optionType: OptionType;
  @IsOptional() @IsInt() @Min(0) minSelect?: number;
  @IsOptional() @IsInt() @Min(0) maxSelect?: number;
  @IsOptional() @IsBoolean() isRequired?: boolean;
  @IsOptional() @IsBoolean() allowQuantity?: boolean;
  @IsOptional() @IsInt() displayOrder?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateOptionChoiceDto)
  choices?: CreateOptionChoiceDto[];
}
