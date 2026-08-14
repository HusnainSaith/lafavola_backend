import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsNotEmpty, IsString, Matches } from 'class-validator';

export class VerifyEmailCodeDto {
  @ApiProperty({
    example: '123456',
    pattern: '^\\d{6}$',
    minLength: 6,
    maxLength: 6,
    description: 'Single-use email verification code',
  })
  @IsString({ message: 'Verification code must be a string' })
  @IsNotEmpty({ message: 'Verification code is required' })
  @Matches(/^\d{6}$/, {
    message: 'Verification code must contain exactly 6 digits',
  })
  @Transform(({ value }) => value?.trim())
  code: string;
}
