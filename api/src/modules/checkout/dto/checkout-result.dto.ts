import { ApiProperty } from '@nestjs/swagger';

export class AppliedPromotionDto {
  @ApiProperty() id: string;
  @ApiProperty() name: string;
  @ApiProperty() type: string;
  @ApiProperty() discountMinor: number;
  @ApiProperty() deliveryDiscountMinor: number;
}

export class CheckoutResultDto {
  @ApiProperty() orderId: string;
  @ApiProperty() orderNumber: string;
  @ApiProperty() status: string;
  @ApiProperty() paymentStatus: string;
  @ApiProperty() amountMinor: number;
  @ApiProperty() currency: string;
  @ApiProperty() subtotalMinor: number;
  @ApiProperty() optionChargesMinor: number;
  @ApiProperty() deliveryFeeMinor: number;
  @ApiProperty() taxMinor: number;
  @ApiProperty() promotionDiscountMinor: number;
  @ApiProperty() couponDiscountMinor: number;
  @ApiProperty() loyaltyDiscountMinor: number;
  @ApiProperty() deliveryDiscountMinor: number;
  @ApiProperty({ type: [AppliedPromotionDto] })
  appliedPromotions: AppliedPromotionDto[];
  @ApiProperty({ required: false }) estimatedDeliveryAt?: Date;
}
