import { IsInt, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class UpdateCartItemDto {
  @IsOptional() @IsInt() @Min(1) quantity?: number;
  @IsOptional() @IsString() @MaxLength(1000) specialInstructions?: string;
}
