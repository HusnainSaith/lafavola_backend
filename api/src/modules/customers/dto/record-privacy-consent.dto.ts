import { IsBoolean, IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class RecordPrivacyConsentDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(60)
  consentType: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  policyVersion: string;

  @IsBoolean()
  granted: boolean;
}
