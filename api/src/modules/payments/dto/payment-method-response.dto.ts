import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PaymentMethodResponseDto {
  @ApiProperty() id: string;
  @ApiProperty() paymentMethodType: string;
  @ApiPropertyOptional() cardBrand?: string;
  @ApiPropertyOptional() cardLast4?: string;
  @ApiPropertyOptional() expMonth?: number;
  @ApiPropertyOptional() expYear?: number;
  @ApiPropertyOptional() label?: string;
  @ApiProperty() isDefault: boolean;
  @ApiProperty() createdAt: Date;
}
