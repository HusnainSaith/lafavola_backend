import { IsOptional, IsString, MaxLength } from 'class-validator';

/** Employee profile fields only; assignment and lifecycle have separate routes. */
export class UpdateStaffMemberDto {
  @IsOptional() @IsString() @MaxLength(80) employeeCode?: string;
  @IsOptional() @IsString() @MaxLength(120) jobTitle?: string;
}
