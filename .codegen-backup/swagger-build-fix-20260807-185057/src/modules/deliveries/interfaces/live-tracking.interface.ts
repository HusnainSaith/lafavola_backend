export interface LiveTrackingSnapshot {
  orderId: string;
  status: string;
  latitude?: string;
  longitude?: string;
  remainingMinutes?: number;
  estimatedArrivalAt?: Date;
  lastPingedAt?: Date;
}
