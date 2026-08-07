import {
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';
import { PaymentMethodType } from '../enums/payment-method-type.enum';

export class CreatePaymentIntentDto {
  @IsUUID() orderId: string;
  @IsEnum(PaymentMethodType) paymentMethodType: PaymentMethodType;
  @IsOptional() @IsUUID() savedPaymentMethodId?: string;
  @IsOptional() @IsString() @MaxLength(255) idempotencyKey?: string;
}
