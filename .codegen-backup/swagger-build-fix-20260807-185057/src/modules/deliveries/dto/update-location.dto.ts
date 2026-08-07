import {
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNumber,
  IsOptional,
  Min,
} from 'class-validator';

export class UpdateLocationDto {
  @IsLatitude() latitude: string;
  @IsLongitude() longitude: string;
  @IsOptional() @IsNumber() headingDegrees?: number;
  @IsOptional() @IsNumber() @Min(0) speedKph?: number;
  @IsOptional() @IsInt() @Min(0) remainingMinutes?: number;
}
