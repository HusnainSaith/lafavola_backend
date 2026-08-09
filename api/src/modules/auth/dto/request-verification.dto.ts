import { IsEnum } from 'class-validator';
import { VerificationTokenType } from '../enums/verification-token-type.enum';

export class RequestVerificationDto {
  @IsEnum(VerificationTokenType)
  type: VerificationTokenType;
}
