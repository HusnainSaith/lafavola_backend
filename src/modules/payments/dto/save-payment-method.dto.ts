import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { PaymentMethodType } from '../enums/payment-method-type.enum';

export class SavePaymentMethodDto {
  @IsEnum(PaymentMethodType) paymentMethodType: PaymentMethodType;
  @IsString() @MaxLength(255) providerPaymentMethodId: string;
  @IsOptional() @IsBoolean() isDefault?: boolean;
  @IsOptional() @IsString() @MaxLength(80) label?: string;
}
