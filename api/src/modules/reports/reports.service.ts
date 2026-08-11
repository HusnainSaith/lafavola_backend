import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { StaffMember } from '../staff/entities/staff-member.entity';
import { SalesReportQueryDto } from './dto/sales-report-query.dto';

const RECOGNIZED = `o.status IN ('delivered','closed') AND o.payment_status IN ('paid','partially_refunded','refunded')`;

@Injectable()
export class ReportsService {
  constructor(private readonly dataSource: DataSource) {}

  async salesForAdmin(actorUserId: string, query: SalesReportQueryDto) {
    return this.sales({
      ...query,
      restaurantId: await this.restaurantIdForActor(actorUserId),
    });
  }

  async dailyRevenueForAdmin(actorUserId: string, query: SalesReportQueryDto) {
    return this.dailyRevenue({
      ...query,
      restaurantId: await this.restaurantIdForActor(actorUserId),
    });
  }

  async popularItemsForAdmin(actorUserId: string, query: SalesReportQueryDto) {
    return this.popularItems({
      ...query,
      restaurantId: await this.restaurantIdForActor(actorUserId),
    });
  }

  async sales(query: SalesReportQueryDto) {
    this.validateRange(query);
    const [row] = await this.dataSource.query(
      `WITH recognized AS (
         SELECT o.* FROM orders o
         WHERE (${RECOGNIZED})
           AND ($1::uuid IS NULL OR o.restaurant_id=$1)
           AND o.created_at >= $2::date
           AND o.created_at < ($3::date + INTERVAL '1 day')
       ), refunded AS (
         SELECT COALESCE(SUM(r.amount_minor),0)::bigint AS amount
         FROM refunds r JOIN recognized o ON o.id=r.order_id
         WHERE r.status='refunded'
       )
       SELECT
         (SELECT COUNT(*) FROM orders o WHERE ($1::uuid IS NULL OR o.restaurant_id=$1)
           AND o.created_at >= $2::date AND o.created_at < ($3::date + INTERVAL '1 day'))::int AS "totalOrders",
         COUNT(*)::int AS "successfulOrders",
         COALESCE(SUM(subtotal_minor + option_charges_minor + delivery_fee_minor + tax_minor),0)::bigint AS "grossSalesMinor",
         COALESCE(SUM(grand_total_minor),0)::bigint AS "recognizedRevenueMinor",
         COALESCE(SUM(discount_minor),0)::bigint AS "discountMinor",
         COALESCE(SUM(tax_minor),0)::bigint AS "taxMinor",
         COALESCE(SUM(delivery_fee_minor),0)::bigint AS "deliveryFeesMinor",
         (SELECT amount FROM refunded)::bigint AS "refundsMinor",
         (COALESCE(SUM(grand_total_minor),0) - (SELECT amount FROM refunded))::bigint AS "netRevenueMinor",
         CASE WHEN COUNT(*)=0 THEN 0 ELSE ROUND(SUM(grand_total_minor)::numeric/COUNT(*))::bigint END AS "averageOrderValueMinor"
       FROM recognized`,
      [query.restaurantId ?? null, query.from, query.to],
    );
    return this.numeric(row);
  }

  async dailyRevenue(query: SalesReportQueryDto) {
    this.validateRange(query);
    const rows = await this.dataSource.query(
      `WITH days AS (
         SELECT generate_series($2::date,$3::date,INTERVAL '1 day')::date AS day
       ), order_daily AS (
         SELECT o.created_at::date AS day, COUNT(*)::int AS orders,
           SUM(o.grand_total_minor)::bigint AS revenue,
           SUM(o.discount_minor)::bigint AS discounts,
           SUM(o.tax_minor)::bigint AS tax,
           SUM(o.delivery_fee_minor)::bigint AS delivery_fees
         FROM orders o
         WHERE (${RECOGNIZED}) AND ($1::uuid IS NULL OR o.restaurant_id=$1)
           AND o.created_at >= $2::date AND o.created_at < ($3::date + INTERVAL '1 day')
         GROUP BY o.created_at::date
       ), refund_daily AS (
         SELECT o.created_at::date AS day, SUM(r.amount_minor)::bigint AS refunds
         FROM refunds r JOIN orders o ON o.id=r.order_id
         WHERE r.status='refunded' AND (${RECOGNIZED})
           AND ($1::uuid IS NULL OR o.restaurant_id=$1)
           AND o.created_at >= $2::date AND o.created_at < ($3::date + INTERVAL '1 day')
         GROUP BY o.created_at::date
       )
       SELECT d.day::text AS date, COALESCE(od.orders,0)::int AS "successfulOrders",
         COALESCE(od.revenue,0)::bigint AS "recognizedRevenueMinor",
         COALESCE(od.discounts,0)::bigint AS "discountMinor",
         COALESCE(od.tax,0)::bigint AS "taxMinor",
         COALESCE(od.delivery_fees,0)::bigint AS "deliveryFeesMinor",
         COALESCE(rd.refunds,0)::bigint AS "refundsMinor",
         (COALESCE(od.revenue,0)-COALESCE(rd.refunds,0))::bigint AS "netRevenueMinor"
       FROM days d LEFT JOIN order_daily od ON od.day=d.day
       LEFT JOIN refund_daily rd ON rd.day=d.day ORDER BY d.day`,
      [query.restaurantId ?? null, query.from, query.to],
    );
    return rows.map((row: Record<string, unknown>) => this.numeric(row));
  }

  async popularItems(query: SalesReportQueryDto) {
    this.validateRange(query);
    const rows = await this.dataSource.query(
      `SELECT i.menu_item_id AS "menuItemId", MAX(i.item_name_snapshot) AS name,
         SUM(i.quantity)::int AS quantity, SUM(i.line_total_minor)::bigint AS "revenueMinor"
       FROM order_items i JOIN orders o ON o.id=i.order_id
       WHERE (${RECOGNIZED}) AND ($1::uuid IS NULL OR o.restaurant_id=$1)
         AND o.created_at >= $2::date AND o.created_at < ($3::date + INTERVAL '1 day')
       GROUP BY i.menu_item_id,i.item_name_snapshot
       ORDER BY SUM(i.quantity) DESC, i.item_name_snapshot ASC LIMIT 20`,
      [query.restaurantId ?? null, query.from, query.to],
    );
    return rows.map((row: Record<string, unknown>) => this.numeric(row));
  }

  private numeric(row: Record<string, unknown>) {
    return Object.fromEntries(
      Object.entries(row).map(([key, value]) => [
        key,
        typeof value === 'string' && /^-?\d+$/.test(value)
          ? Number(value)
          : value,
      ]),
    );
  }

  private async restaurantIdForActor(actorUserId: string) {
    const staff = await this.dataSource.getRepository(StaffMember).findOne({
      where: { userId: actorUserId, isActive: true },
      select: { restaurantId: true },
    });
    if (!staff) throw new NotFoundException('Staff member not found');
    return staff.restaurantId;
  }

  private validateRange(query: SalesReportQueryDto) {
    if (new Date(query.from).getTime() > new Date(query.to).getTime())
      throw new BadRequestException(
        'Report start date must not exceed end date',
      );
  }
}
