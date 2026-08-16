import {
  IsDateString,
  IsDefined,
  IsEnum,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  ValidateIf,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PaymentMethodType } from '../../payments/enums/payment-method-type.enum';

export class CheckoutDto {
  @IsUUID()
  cartId: string;

  @IsIn(['delivery', 'pickup'])
  orderType: 'delivery' | 'pickup';

  @ValidateIf((dto: CheckoutDto) => dto.orderType === 'delivery')
  @IsUUID()
  deliveryAddressId?: string;

  @IsEnum(PaymentMethodType)
  paymentMethod: PaymentMethodType;

  @IsOptional()
  @IsUUID()
  savedPaymentMethodId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  couponCode?: string;

  @ApiPropertyOptional({
    description:
      'Number of loyalty points the customer wants to redeem against this order.',
    example: 250,
    minimum: 1,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  loyaltyPointsToRedeem?: number;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  customerNote?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  deliveryInstructions?: string;

  @IsOptional()
  @IsDateString()
  scheduledFor?: string;

  @IsDefined()
  @IsString()
  @MaxLength(255)
  @ApiProperty({ minLength: 1, maxLength: 255 })
  idempotencyKey: string;
}
