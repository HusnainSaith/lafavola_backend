import { IsBoolean, IsOptional, IsString } from 'class-validator';

export class UpdateNotificationPreferencesDto {
  @IsOptional() @IsBoolean() pushOrderUpdates?: boolean;
  @IsOptional() @IsBoolean() smsOrderUpdates?: boolean;
  @IsOptional() @IsBoolean() emailOrderUpdates?: boolean;
  @IsOptional() @IsBoolean() pushPromotions?: boolean;
  @IsOptional() @IsBoolean() smsPromotions?: boolean;
  @IsOptional() @IsBoolean() emailPromotions?: boolean;
  @IsOptional() @IsBoolean() couponExpirationAlerts?: boolean;
  @IsOptional() @IsString() quietHoursStart?: string;
  @IsOptional() @IsString() quietHoursEnd?: string;
}
