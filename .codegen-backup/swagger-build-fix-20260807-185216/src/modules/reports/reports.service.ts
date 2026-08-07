import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { SalesReportQueryDto } from './dto/sales-report-query.dto';
import { Order } from '../orders/entities/order.entity';
import { OrderItem } from '../orders/entities/order-item.entity';

@Injectable()
export class ReportsService {
  constructor(private readonly dataSource: DataSource) {}

  async sales(query: SalesReportQueryDto) {
    const qb = this.dataSource
      .getRepository(Order)
      .createQueryBuilder('o')
      .select('COUNT(o.id)', 'totalOrders')
      .addSelect(
        "COALESCE(SUM(CASE WHEN o.status IN ('delivered','closed') THEN o.grand_total_minor ELSE 0 END),0)",
        'revenueMinor',
      )
      .addSelect('COALESCE(SUM(o.discount_minor),0)', 'discountMinor')
      .addSelect('COALESCE(SUM(o.tax_minor),0)', 'taxMinor')
      .where('o.restaurant_id = :restaurantId', {
        restaurantId: query.restaurantId,
      });

    if (query.from) qb.andWhere('o.created_at >= :from', { from: query.from });
    if (query.to)
      qb.andWhere("o.created_at < (:to::date + INTERVAL '1 day')", {
        to: query.to,
      });

    return qb.getRawOne();
  }

  async popularItems(query: SalesReportQueryDto) {
    const qb = this.dataSource
      .getRepository(OrderItem)
      .createQueryBuilder('i')
      .innerJoin(Order, 'o', 'o.id = i.order_id')
      .select('i.menu_item_id', 'menuItemId')
      .addSelect('MAX(i.item_name_snapshot)', 'name')
      .addSelect('SUM(i.quantity)', 'quantity')
      .addSelect('SUM(i.line_total_minor)', 'revenueMinor')
      .where('o.restaurant_id = :restaurantId', {
        restaurantId: query.restaurantId,
      })
      .andWhere("o.status IN ('delivered','closed')");

    if (query.from) qb.andWhere('o.created_at >= :from', { from: query.from });
    if (query.to)
      qb.andWhere("o.created_at < (:to::date + INTERVAL '1 day')", {
        to: query.to,
      });

    return qb
      .groupBy('i.menu_item_id')
      .orderBy('SUM(i.quantity)', 'DESC')
      .limit(20)
      .getRawMany();
  }
}
