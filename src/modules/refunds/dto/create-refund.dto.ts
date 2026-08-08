import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateRefundDto {
  @ApiProperty() @IsUUID() orderId: string;
  @ApiProperty({ example: 500 }) @IsInt() @Min(1) amountMinor: number;
  @ApiProperty() @IsString() @MaxLength(80) reason: string;
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  customerReason?: string;
  @ApiProperty() @IsString() @MaxLength(255) idempotencyKey: string;
}
