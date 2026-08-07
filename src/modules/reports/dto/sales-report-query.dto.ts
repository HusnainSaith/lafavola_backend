import { IsDateString, IsOptional, IsUUID } from 'class-validator';

export class SalesReportQueryDto {
  @IsOptional() @IsUUID() restaurantId?: string;
  @IsDateString() from: string;
  @IsDateString() to: string;
}
