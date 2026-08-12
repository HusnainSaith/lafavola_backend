import { IsBoolean, IsOptional, IsUUID } from 'class-validator';

export class UpdateCustomerPreferencesDto {
  @IsOptional() @IsBoolean() marketingEmailOptIn?: boolean;
  @IsOptional() @IsBoolean() vegetarianPreference?: boolean;
  @IsOptional() @IsBoolean() veganPreference?: boolean;
  @IsOptional() @IsBoolean() glutenFreePreference?: boolean;
  @IsOptional() @IsBoolean() spicyPreference?: boolean;
  @IsOptional() @IsUUID() defaultPaymentMethodId?: string;
}
