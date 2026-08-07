import {
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';
import { PaymentMethodType } from '../../payments/enums/payment-method-type.enum';

export class CheckoutDto {
  @IsUUID() cartId: string;
  @IsUUID() deliveryAddressId: string;
  @IsEnum(PaymentMethodType) paymentMethod: PaymentMethodType;
  @IsOptional() @IsUUID() savedPaymentMethodId?: string;
  @IsOptional() @IsString() @MaxLength(80) couponCode?: string;
  @IsOptional() @IsString() @MaxLength(1000) customerNote?: string;
  @IsOptional() @IsString() idempotencyKey?: string;
}
