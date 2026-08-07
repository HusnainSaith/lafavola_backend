import {
  IsBoolean,
  IsLatitude,
  IsLongitude,
  IsOptional,
  IsPhoneNumber,
  IsString,
  Length,
  MaxLength,
} from 'class-validator';

export class CreateAddressDto {
  @IsOptional()
  @IsString()
  @MaxLength(80)
  label?: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  recipientName?: string;

  @IsOptional()
  @IsPhoneNumber()
  phone?: string;

  @IsString()
  @MaxLength(255)
  addressLine1: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  addressLine2?: string;

  @IsString()
  @MaxLength(120)
  city: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  province?: string;

  @IsString()
  @MaxLength(24)
  postalCode: string;

  @IsOptional()
  @IsString()
  @Length(2, 2)
  countryCode?: string;

  @IsOptional()
  @IsLatitude()
  latitude?: string;

  @IsOptional()
  @IsLongitude()
  longitude?: string;

  @IsOptional()
  @IsString()
  deliveryInstructions?: string;

  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}
