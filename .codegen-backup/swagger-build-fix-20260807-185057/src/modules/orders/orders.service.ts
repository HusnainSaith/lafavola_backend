import { BadRequestException, Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { OrderRepository } from './repositories/order.repository';
import { Order } from './entities/order.entity';
import { OrderStatusHistory } from './entities/order-status-history.entity';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { OrderStatus } from './enums/order-status.enum';
import { requireEntity } from '../../common/utils/service-errors.util';

const TRANSITIONS: Record<string, string[]> = {
  pending_payment: ['placed', 'cancelled'],
  placed: ['accepted', 'rejected', 'cancelled'],
  accepted: ['preparing', 'cancelled'],
  preparing: ['baking', 'cancelled'],
  baking: ['packing'],
  packing: ['ready'],
  ready: ['driver_assigned', 'out_for_delivery'],
  driver_assigned: ['out_for_delivery'],
  out_for_delivery: ['delivered'],
  delivered: ['closed'],
  closed: [],
  cancelled: [],
  rejected: [],
};

@Injectable()
export class OrdersService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly orders: OrderRepository,
  ) {}

  async customerHistory(customerId: string): Promise<Order[]> {
    return this.orders.findCustomerHistory(customerId);
  }

  async customerDetail(customerId: string, orderId: string): Promise<Order> {
    return requireEntity(
      await this.orders.findOne({
        where: { id: orderId, customerId },
      }),
      'Order not found',
    );
  }

  listAdmin(restaurantId?: string, status?: string) {
    return this.orders.findMany({
      where: {
        ...(restaurantId ? { restaurantId } : {}),
        ...(status ? { status } : {}),
      } as any,
      order: { createdAt: 'DESC' },
    });
  }

  async updateStatus(
    orderId: string,
    dto: UpdateOrderStatusDto,
    actorUserId?: string,
  ): Promise<Order> {
    const order = requireEntity(
      await this.orders.findById(orderId),
      'Order not found',
    );
    const current = String(order.status);
    const next = String(dto.status);
    if (!(TRANSITIONS[current] ?? []).includes(next)) {
      throw new BadRequestException(
        `Invalid order transition: ${current} -> ${next}`,
      );
    }

    return this.dataSource.transaction(async (manager) => {
      const orderRepo = manager.getRepository(Order);
      const historyRepo = manager.getRepository(OrderStatusHistory);
      const previous = order.status;
      order.status = dto.status as any;
      order.version = Number(order.version) + 1;
      if (next === 'placed') order.placedAt = order.placedAt ?? new Date();
      if (next === 'accepted') order.acceptedAt = new Date();
      if (next === 'delivered') order.deliveredAt = new Date();
      if (next === 'cancelled') {
        order.cancelledAt = new Date();
        order.cancellationReason = dto.note;
      }
      const saved = await orderRepo.save(order);
      await historyRepo.save(
        historyRepo.create({
          orderId: saved.id,
          previousStatus: String(previous),
          newStatus: next,
          changedByUserId: actorUserId,
          note: dto.note,
        }),
      );
      return saved;
    });
  }

  async cancelByCustomer(customerId: string, orderId: string, reason?: string) {
    const order = await this.customerDetail(customerId, orderId);
    if (
      !['pending_payment', 'placed', 'accepted'].includes(String(order.status))
    ) {
      throw new BadRequestException('Order can no longer be cancelled');
    }
    return this.updateStatus(
      order.id,
      { status: OrderStatus.CANCELLED, note: reason } as UpdateOrderStatusDto,
      customerId,
    );
  }
}
