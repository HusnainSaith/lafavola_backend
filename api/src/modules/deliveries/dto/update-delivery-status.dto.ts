import { IsEnum } from 'class-validator';
import { DeliveryAssignmentStatus } from '../enums/delivery-assignment-status.enum';

export class UpdateDeliveryStatusDto {
  @IsEnum(DeliveryAssignmentStatus)
  status: DeliveryAssignmentStatus;
}
