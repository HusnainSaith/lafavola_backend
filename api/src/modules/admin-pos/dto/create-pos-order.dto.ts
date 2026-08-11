import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsPhoneNumber,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';

export class PosOrderOptionDto {
  @IsOptional() @IsUUID() optionGroupId?: string;
  @IsOptional() @IsUUID() optionChoiceId?: string;
  @IsOptional() @IsUUID() ingredientId?: string;
  @IsOptional() @IsIn(['add', 'remove', 'replace']) action?: string = 'add';
  @IsOptional() @IsInt() @Min(1) @Max(20) quantity?: number = 1;
}

export class PosOrderItemDto {
  @IsUUID() menuItemId: string;
  @IsUUID() sizeId: string;
  @IsInt() @Min(1) @Max(99) quantity: number;
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(40)
  @ValidateNested({ each: true })
  @Type(() => PosOrderOptionDto)
  options?: PosOrderOptionDto[] = [];
  @IsOptional() @IsString() @MaxLength(500) specialInstructions?: string;
}

export class CreatePosOrderDto {
  @IsIn(['dine_in', 'takeaway']) orderType: 'dine_in' | 'takeaway';

  @ValidateIf((value: CreatePosOrderDto) => value.orderType === 'dine_in')
  @IsString()
  @MaxLength(40)
  tableLabel?: string;

  @IsOptional() @IsString() @MaxLength(120) customerName?: string;
  @IsOptional() @IsPhoneNumber() customerPhone?: string;
  @IsOptional() @IsString() @MaxLength(1000) customerNote?: string;
  @IsIn(['cash', 'card_on_delivery'])
  paymentMethod: 'cash' | 'card_on_delivery';
  @IsString() @MaxLength(255) idempotencyKey: string;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(80)
  @ValidateNested({ each: true })
  @Type(() => PosOrderItemDto)
  items: PosOrderItemDto[];
}
