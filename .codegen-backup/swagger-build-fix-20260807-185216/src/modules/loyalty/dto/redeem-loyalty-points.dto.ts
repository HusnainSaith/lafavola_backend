import { IsInt, IsUUID, Min } from 'class-validator';

export class RedeemLoyaltyPointsDto {
  @IsUUID() orderId: string;
  @IsInt() @Min(1) points: number;
}
