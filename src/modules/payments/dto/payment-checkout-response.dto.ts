import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PaymentCheckoutResponseDto {
  @ApiProperty() id: string;
  @ApiProperty() orderId: string;
  @ApiProperty({ example: 'pending' }) status: string;
  @ApiProperty({ example: 1299 }) amountMinor: number;
  @ApiProperty({ example: 'EUR' }) currency: string;
  @ApiPropertyOptional() checkoutId?: string;
  @ApiPropertyOptional() hostedCheckoutUrl?: string;
}
