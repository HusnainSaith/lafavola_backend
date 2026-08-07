import {
  IsDateString,
  IsEnum,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNumber,
  IsOptional,
  Min,
} from 'class-validator';
import { DeliveryTrackingStatus } from '../enums/delivery-tracking-status.enum';

export class UpdateLocationDto {
  @IsLatitude()
  latitude: string;

  @IsLongitude()
  longitude: string;

  @IsOptional()
  @IsNumber()
  headingDegrees?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  speedKph?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  remainingMinutes?: number;

  @IsOptional()
  @IsDateString()
  estimatedArrivalAt?: string;

  @IsOptional()
  @IsEnum(DeliveryTrackingStatus)
  status?: DeliveryTrackingStatus;
}
