import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayUnique,
  IsArray,
  IsInt,
  IsOptional,
  IsPositive,
  IsUUID,
  IsIn,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class PricingOptionSelectionDto {
  @IsOptional() @IsUUID() optionGroupId?: string;
  @IsOptional() @IsUUID() optionChoiceId?: string;
  @IsOptional() @IsUUID() ingredientId?: string;
  @IsOptional() @IsIn(['add', 'remove', 'replace']) action?:
    'add' | 'remove' | 'replace';
  @IsOptional() @Min(0.01) quantity?: number;
}

export class CalculatePriceDto {
  @ApiProperty({
    description: 'Menu item ID',
    example: '4a9bb40f-5c7e-4cc5-bb08-e5d8792cab90',
  })
  @IsUUID()
  menuItemId: string;

  @ApiPropertyOptional({
    description: 'Selected menu item size ID',
    example: '279a8d46-a1ce-48f8-ae40-b9fb11e32f98',
  })
  @IsOptional()
  @IsUUID()
  sizeId?: string;

  @ApiPropertyOptional({
    description: 'Selected option choice IDs',
    type: [String],
    example: [
      'e60c7896-a469-41fb-881e-fcef61d3061b',
      '0788df92-78cf-40b7-bc70-97d0e950d4ec',
    ],
  })
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsUUID('4', { each: true })
  optionChoiceIds?: string[];

  @ApiPropertyOptional({ type: [PricingOptionSelectionDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PricingOptionSelectionDto)
  options?: PricingOptionSelectionDto[];

  @ApiPropertyOptional({
    description: 'Quantity',
    example: 1,
    minimum: 1,
    default: 1,
  })
  @IsOptional()
  @IsInt()
  @IsPositive()
  quantity?: number;
}
