import { PartialType } from '@nestjs/mapped-types';
import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';

export class CreatePizzaBuilderRuleDto {
  @IsUUID() menuItemId: string;
  @IsString() @MaxLength(160) name: string;
  @IsOptional() @IsUUID() sizeGroupId?: string;
  @IsOptional() @IsUUID() doughGroupId?: string;
  @IsOptional() @IsUUID() sauceGroupId?: string;
  @IsOptional() @IsUUID() cheeseGroupId?: string;
  @IsOptional() @IsUUID() toppingsGroupId?: string;
  @IsOptional() @IsInt() @Min(0) maxTotalToppings?: number;
  @IsOptional() @IsInt() @Min(0) freeToppingCount?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}

export class UpdatePizzaBuilderRuleDto extends PartialType(
  CreatePizzaBuilderRuleDto,
) {}
