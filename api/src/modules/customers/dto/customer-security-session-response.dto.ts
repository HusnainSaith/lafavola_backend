import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CustomerSecuritySessionResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'date-time' })
  createdAt: Date;

  @ApiProperty({ format: 'date-time' })
  expiresAt: Date;

  @ApiProperty()
  revoked: boolean;

  @ApiPropertyOptional({
    format: 'date-time',
    nullable: true,
    description: 'Present only after the refresh session has been revoked',
  })
  revokedAt?: Date | null;
}

export type CustomerSecuritySessionView = CustomerSecuritySessionResponseDto;
