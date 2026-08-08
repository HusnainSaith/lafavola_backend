import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class SocialLoginDto {
  @ApiProperty({
    description: 'The identity token returned by Google or Apple',
    example: 'eyJhbGciOiJSUzI1NiIsImtpZCI6Ii4uLiJ9...',
  })
  @IsString()
  @MinLength(1)
  @MaxLength(4096)
  idToken: string;

  @ApiPropertyOptional({
    description:
      'Name supplied on first sign-in (especially for Apple, which only supplies it once)',
    example: 'Mario Rossi',
  })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(160)
  fullName?: string;
}
