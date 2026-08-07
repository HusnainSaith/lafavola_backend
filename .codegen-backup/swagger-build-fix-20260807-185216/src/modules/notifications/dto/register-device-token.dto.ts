import { IsEnum, IsString, MaxLength } from 'class-validator';
import { DevicePlatform } from '../enums/device-platform.enum';

export class RegisterDeviceTokenDto {
  @IsEnum(DevicePlatform) platform: DevicePlatform;
  @IsString() @MaxLength(4096) token: string;
}
