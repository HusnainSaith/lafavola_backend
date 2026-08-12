import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PrivacyRequestStatus } from '../enums/privacy-request-status.enum';
import { PrivacyRequestType } from '../enums/privacy-request-type.enum';

export class PrivacyRequestResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ enum: PrivacyRequestType })
  requestType: PrivacyRequestType;

  @ApiProperty({ enum: PrivacyRequestStatus })
  status: PrivacyRequestStatus;

  @ApiProperty({ format: 'date-time' })
  requestedAt: Date;

  @ApiPropertyOptional({
    format: 'date-time',
    nullable: true,
    description: 'Present only after the request has completed',
  })
  completedAt?: Date | null;
}
