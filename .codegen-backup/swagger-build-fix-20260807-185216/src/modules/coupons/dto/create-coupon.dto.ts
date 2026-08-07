import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';
import { DiscountType } from '../enums/discount-type.enum';

export class CreateCouponDto {
  @IsUUID() restaurantId: string;
  @IsOptional() @IsUUID() promotionId?: string;
  @IsString() @MaxLength(80) code: string;
  @IsOptional() @IsString() description?: string;
  @IsEnum(DiscountType) discountType: DiscountType;
  @IsOptional() @IsInt() @Min(0) discountValue?: number;
  @IsOptional() @IsInt() @Min(0) minOrderMinor?: number;
  @IsOptional() @IsInt() @Min(0) maxDiscountMinor?: number;
  @IsOptional() @IsDateString() startsAt?: string;
  @IsOptional() @IsDateString() expiresAt?: string;
  @IsOptional() @IsInt() @Min(1) totalUsageLimit?: number;
  @IsOptional() @IsInt() @Min(1) perCustomerLimit?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
