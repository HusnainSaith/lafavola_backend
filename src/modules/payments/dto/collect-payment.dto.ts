import { IsEnum, IsString, IsUUID, MaxLength } from 'class-validator';
import { PaymentMethodType } from '../enums/payment-method-type.enum';

export class CollectPaymentDto {
  @IsUUID() orderId: string;
  @IsEnum(PaymentMethodType) paymentMethodType: PaymentMethodType;
  @IsString() @MaxLength(255) idempotencyKey: string;
}
