import {
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateRefundDto {
  @IsUUID() orderId: string;
  @IsOptional() @IsUUID() paymentTransactionId?: string;
  @IsInt() @Min(1) amountMinor: number;
  @IsString() @MaxLength(80) reason: string;
  @IsOptional() @IsString() @MaxLength(2000) customerReason?: string;
}
