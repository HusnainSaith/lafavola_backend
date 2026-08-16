import { PartialType } from '@nestjs/mapped-types';
import { IsInt, IsOptional, IsUUID, Min } from 'class-validator';
import { ApplyCouponDto } from './apply-coupon.dto';

export class ValidateCouponDto extends PartialType(ApplyCouponDto) {
  @IsOptional()
  @IsInt()
  @Min(0)
  subtotalMinor?: number;

  @IsOptional()
  @IsUUID()
  restaurantId?: string;
}
