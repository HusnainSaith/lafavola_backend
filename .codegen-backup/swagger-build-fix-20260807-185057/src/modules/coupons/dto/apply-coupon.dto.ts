import { IsString, MaxLength } from 'class-validator';

export class ApplyCouponDto {
  @IsString()
  @MaxLength(80)
  code: string;
}
