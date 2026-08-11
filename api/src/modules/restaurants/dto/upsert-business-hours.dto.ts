import {
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsOptional,
  Matches,
  Max,
  Min,
  ValidateIf,
} from 'class-validator';

export class UpsertBusinessHoursDto {
  @IsInt() @Min(0) @Max(6) dayOfWeek: number;

  @ValidateIf((dto: UpsertBusinessHoursDto) => dto.isClosed !== true)
  @IsNotEmpty()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: 'opensAt must be a 24-hour HH:mm time',
  })
  opensAt?: string;

  @ValidateIf((dto: UpsertBusinessHoursDto) => dto.isClosed !== true)
  @IsNotEmpty()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: 'closesAt must be a 24-hour HH:mm time',
  })
  closesAt?: string;

  @IsOptional() @IsBoolean() isClosed?: boolean;
}
