import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsOptional,
  IsPhoneNumber,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CreateDriverDto {
  @IsString()
  @MinLength(2)
  @MaxLength(160)
  @Transform(({ value }) => value?.trim())
  fullName: string;

  @IsEmail()
  @MaxLength(320)
  @Transform(({ value }) => value?.trim().toLowerCase())
  email: string;

  @IsOptional()
  @IsPhoneNumber()
  phone?: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  temporaryPassword: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  employeeCode?: string;
}
