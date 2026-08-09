export interface AuditContext {
  actorUserId?: string;
  restaurantId?: string;
  correlationId?: string;
  ipAddress?: string;
  userAgent?: string;
  metadata?: Record<string, unknown>;
}
