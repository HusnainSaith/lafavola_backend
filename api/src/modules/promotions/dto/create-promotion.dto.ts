import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';
import { PromotionType } from '../enums/promotion-type.enum';

export class CreatePromotionDto {
  @IsUUID() restaurantId: string;
  @IsString() @MaxLength(180) name: string;
  @IsOptional() @IsString() description?: string;
  @IsEnum(PromotionType) promotionType: PromotionType;
  @IsOptional() @IsInt() @Min(0) discountValue?: number;
  @IsOptional() @IsInt() @Min(0) minOrderMinor?: number;
  @IsOptional() @IsInt() @Min(0) maxDiscountMinor?: number;
  @IsDateString() startsAt: string;
  @IsOptional() @IsDateString() endsAt?: string;
  @IsOptional() @IsInt() @Min(1) totalUsageLimit?: number;
  @IsOptional() @IsInt() @Min(1) perCustomerLimit?: number;
  @IsOptional() @IsInt() priority?: number;
  @IsOptional() @IsString() @MaxLength(80) stackingGroup?: string;
  @IsOptional() @IsBoolean() isAutomatic?: boolean;
  @IsOptional() @IsBoolean() isActive?: boolean;
  @IsOptional() @IsObject() conditions?: Record<string, unknown>;
  @IsOptional() @IsObject() actions?: Record<string, unknown>;
}
