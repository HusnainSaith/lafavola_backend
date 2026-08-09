import {
  IsBoolean,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class CreateStaffMemberDto {
  @IsUUID() userId: string;
  @IsUUID() restaurantId: string;
  @IsOptional() @IsString() @MaxLength(80) employeeCode?: string;
  @IsOptional() @IsString() @MaxLength(120) jobTitle?: string;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
