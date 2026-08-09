import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';

export class CreateFaqDto {
  @IsOptional() @IsUUID() restaurantId?: string;
  @IsOptional() @IsUUID() categoryId?: string;
  @IsString() question: string;
  @IsString() answer: string;
  @IsOptional() @IsInt() @Min(0) displayOrder?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
}
