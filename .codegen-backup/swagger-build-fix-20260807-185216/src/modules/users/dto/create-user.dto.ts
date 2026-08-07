import {
  IsEmail,
  IsEnum,
  IsOptional,
  IsPhoneNumber,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { UserStatus } from '../enums/user-status.enum';

export class CreateUserDto {
  @IsOptional()
  @IsEmail()
  @MaxLength(320)
  @Transform(({ value }) => value?.trim().toLowerCase())
  email?: string;

  @IsOptional()
  @IsPhoneNumber()
  phone?: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password: string;

  @IsString()
  @MaxLength(160)
  @Transform(({ value }) => value?.trim())
  fullName: string;

  @IsOptional()
  @IsUUID()
  roleId?: string;

  @IsOptional()
  @IsEnum(UserStatus)
  status?: UserStatus;
}
