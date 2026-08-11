import { Injectable, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { DeliveryAssignment } from '../deliveries/entities/delivery-assignment.entity';
import { Order } from '../orders/entities/order.entity';
import { Refund } from '../refunds/entities/refund.entity';
import { StaffMember } from '../staff/entities/staff-member.entity';
import { SupportTicket } from '../support/entities/support-ticket.entity';

@Injectable()
export class AdminDashboardService {
  constructor(private readonly dataSource: DataSource) {}

  async summary(actorUserId: string) {
    const staff = await this.dataSource.getRepository(StaffMember).findOne({
      where: { userId: actorUserId, isActive: true },
    });
    if (!staff) throw new NotFoundException('Staff member not found');

    const startOfDay = new Date();
    startOfDay.setUTCHours(0, 0, 0, 0);
    const orderBase = () =>
      this.dataSource
        .getRepository(Order)
        .createQueryBuilder('order')
        .where('order.restaurant_id = :restaurantId', {
          restaurantId: staff.restaurantId,
        });

    const [
      todayOrders,
      attentionOrders,
      readyOrders,
      deliveries,
      refunds,
      support,
      revenue,
    ] = await Promise.all([
      orderBase()
        .andWhere('order.created_at >= :startOfDay', { startOfDay })
        .getCount(),
      orderBase()
        .andWhere('order.status IN (:...statuses)', {
          statuses: ['placed', 'accepted', 'preparing', 'baking', 'packing'],
        })
        .getCount(),
      orderBase()
        .andWhere('order.status = :ready', { ready: 'ready' })
        .getCount(),
      this.dataSource
        .getRepository(DeliveryAssignment)
        .createQueryBuilder('assignment')
        .innerJoin('assignment.order', 'order')
        .where('order.restaurant_id = :restaurantId', {
          restaurantId: staff.restaurantId,
        })
        .andWhere('assignment.status NOT IN (:...terminal)', {
          terminal: ['delivered', 'failed', 'cancelled'],
        })
        .getCount(),
      this.dataSource
        .getRepository(Refund)
        .createQueryBuilder('refund')
        .innerJoin('refund.order', 'order')
        .where('order.restaurant_id = :restaurantId', {
          restaurantId: staff.restaurantId,
        })
        .andWhere('refund.status = :requested', { requested: 'requested' })
        .getCount(),
      this.dataSource
        .getRepository(SupportTicket)
        .createQueryBuilder('ticket')
        .innerJoin('ticket.order', 'order')
        .where('order.restaurant_id = :restaurantId', {
          restaurantId: staff.restaurantId,
        })
        .andWhere('ticket.status NOT IN (:...terminal)', {
          terminal: ['resolved', 'closed'],
        })
        .getCount(),
      orderBase()
        .select('COALESCE(SUM(order.grand_total_minor), 0)', 'total')
        .andWhere('order.payment_status = :paid', { paid: 'paid' })
        .andWhere('order.created_at >= :startOfDay', { startOfDay })
        .getRawOne<{ total: string }>(),
    ]);

    return {
      restaurantId: staff.restaurantId,
      generatedAt: new Date().toISOString(),
      orders: {
        today: todayOrders,
        attention: attentionOrders,
        ready: readyOrders,
      },
      deliveries: { active: deliveries },
      refunds: { requested: refunds },
      support: { open: support },
      revenue: { paidMinorToday: Number(revenue?.total ?? 0), currency: 'EUR' },
    };
  }
}
