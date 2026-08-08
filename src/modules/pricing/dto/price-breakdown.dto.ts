import { ApiProperty } from '@nestjs/swagger';

export class PriceBreakdownDto {
  @ApiProperty() basePriceMinor: number;
  @ApiProperty() optionAdjustmentsMinor: number;
  @ApiProperty() unitPriceMinor: number;
  @ApiProperty() quantity: number;
  @ApiProperty() lineTotalMinor: number;
  @ApiProperty({ example: 'EUR' }) currency: string;
}
