import { IsUUID } from 'class-validator';

export class AssignDriverDto {
  @IsUUID() driverUserId: string;
}
