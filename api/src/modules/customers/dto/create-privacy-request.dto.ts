import { IsEnum } from 'class-validator';
import { PrivacyRequestType } from '../enums/privacy-request-type.enum';

export class CreatePrivacyRequestDto {
  @IsEnum(PrivacyRequestType)
  requestType: PrivacyRequestType;
}
