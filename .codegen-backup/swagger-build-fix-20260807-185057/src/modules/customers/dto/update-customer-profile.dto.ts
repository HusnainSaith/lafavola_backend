import {
  IsBoolean,
  IsDateString,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
} from 'class-validator';

export class UpdateCustomerProfileDto {
  @IsOptional()
  @IsUrl({ require_protocol: true })
  avatarUrl?: string;

  @IsOptional()
  @IsDateString()
  dateOfBirth?: string;

  @IsOptional()
  @IsString()
  @MaxLength(10)
  preferredLanguage?: string;

  @IsOptional()
  @IsBoolean()
  loyaltyOptIn?: boolean;

  @IsOptional()
  @IsBoolean()
  marketingOptIn?: boolean;
}
