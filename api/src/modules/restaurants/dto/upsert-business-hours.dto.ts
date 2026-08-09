import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class UpsertBusinessHoursDto {
  @IsInt() @Min(0) @Max(6) dayOfWeek: number;
  @IsOptional() @IsString() opensAt?: string;
  @IsOptional() @IsString() closesAt?: string;
  @IsOptional() @IsBoolean() isClosed?: boolean;
}
