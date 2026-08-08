import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsUUID, MaxLength } from 'class-validator';

export class CreatePaymentIntentDto {
  @ApiProperty() @IsUUID() orderId: string;
  @ApiProperty() @IsString() @MaxLength(255) idempotencyKey: string;
}
