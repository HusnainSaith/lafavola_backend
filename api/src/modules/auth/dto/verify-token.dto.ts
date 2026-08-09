import { IsString, MaxLength } from 'class-validator';

export class VerifyTokenDto {
  @IsString()
  @MaxLength(512)
  token: string;
}
