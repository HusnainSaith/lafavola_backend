import {
  IsBoolean,
  IsEmail,
  IsEnum,
  IsInt,
  IsOptional,
  IsPhoneNumber,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { TaxBehavior } from '../enums/tax-behavior.enum';

export class CreateRestaurantDto {
  @IsString() @MaxLength(160) name: string;
  @IsString() @MaxLength(180) slug: string;
  @IsOptional() @IsPhoneNumber() phone?: string;
  @IsOptional() @IsEmail() email?: string;
  @IsOptional() @IsString() @MaxLength(255) addressLine1?: string;
  @IsOptional() @IsString() @MaxLength(255) addressLine2?: string;
  @IsOptional() @IsString() @MaxLength(120) city?: string;
  @IsOptional() @IsString() @MaxLength(120) province?: string;
  @IsOptional() @IsString() @MaxLength(24) postalCode?: string;
  @IsOptional() @IsString() @MaxLength(2) countryCode?: string;
  @IsOptional() @IsString() @MaxLength(80) timezone?: string;
  @IsOptional() @IsInt() @Min(1) defaultDeliveryMinutes?: number;
  @IsOptional() @IsInt() @Min(0) deliveryFeeMinor?: number;
  @IsOptional() @IsInt() @Min(0) minimumOrderMinor?: number;
  @IsOptional() @IsInt() @Min(0) @Max(10000) taxRateBasisPoints?: number;
  @IsOptional() @IsEnum(TaxBehavior) taxBehavior?: TaxBehavior;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
