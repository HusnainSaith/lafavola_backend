import { IsEnum, IsString, MaxLength } from 'class-validator';
import { SocialProvider } from '../enums/social-provider.enum';

export class SocialLoginDto {
  @IsEnum(SocialProvider)
  provider: SocialProvider;

  @IsString()
  @MaxLength(4096)
  idToken: string;
}
