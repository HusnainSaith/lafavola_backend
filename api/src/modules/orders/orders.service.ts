import {
  BadRequestException,
  Injectable,
  UnprocessableEntityException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { requireEntity } from '../../common/utils/service-errors.util';
import { CartsService } from '../carts/carts.service';
import { AddCartItemDto } from '../carts/dto/add-cart-item.dto';
import { PricingService } from '../pricing/pricing.service';
import { OrderHistoryQueryDto } from './dto/order-history-query.dto';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { OrderItemOption } from './entities/order-item-option.entity';
import { OrderItem } from './entities/order-item.entity';
import { OrderStatusHistory } from './entities/order-status-history.entity';
import { Order } from './entities/order.entity';
import { OrderStatus } from './enums/order-status.enum';
import { OrderRepository } from './repositories/order.repository';
import { OutboxService } from '../../queue/outbox.service';
import { StaffMember } from '../staff/entities/staff-member.entity';
import { Restaurant } from '../restaurants/entities/restaurant.entity';

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
    private readonly carts: CartsService,
    private readonly pricing: PricingService,
    private readonly outbox: OutboxService,
  ) {}

  async customerHistory(customerId: string, query: OrderHistoryQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const [data, total] = await this.dataSource
      .getRepository(Order)
      .findAndCount({
        where: { customerId },
        order: { createdAt: 'DESC' },
        take: limit,
        skip: (page - 1) * limit,
      });
    return {
      data,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async customerDetail(customerId: string, orderId: string) {
    const order = requireEntity(
      await this.orders.findOne({ where: { id: orderId, customerId } }),
      'Order not found',
    );
    const items = await this.dataSource.getRepository(OrderItem).find({
      where: { orderId },
      order: { createdAt: 'ASC' },
    });
    const options = items.length
      ? await this.dataSource
          .getRepository(OrderItemOption)
          .createQueryBuilder('option')
          .where('option.order_item_id IN (:...ids)', {
            ids: items.map((item) => item.id),
          })
          .getMany()
      : [];
    const statusHistory = await this.dataSource
      .getRepository(OrderStatusHistory)
      .find({ where: { orderId }, order: { occurredAt: 'ASC' } });
    const serverNow = new Date();
    const targetAt = order.estimatedDeliveryAt ?? order.estimatedReadyAt;
    return {
      order,
      items,
      options,
      statusHistory,
      timing: {
        serverNow,
        estimatedReadyAt: order.estimatedReadyAt ?? null,
        estimatedDeliveryAt: order.estimatedDeliveryAt ?? null,
        remainingSeconds: targetAt
          ? Math.max(
              0,
              Math.ceil((targetAt.getTime() - serverNow.getTime()) / 1000),
            )
          : null,
        isFinal: ['delivered', 'closed', 'cancelled', 'rejected'].includes(
          String(order.status),
        ),
      },
    };
  }

  async customerReceipt(customerId: string, orderId: string) {
    const detail = await this.customerDetail(customerId, orderId);
    const restaurant = requireEntity(
      await this.dataSource.getRepository(Restaurant).findOne({
        where: { id: detail.order.restaurantId },
      }),
      'Restaurant not found',
    );
    return {
      documentType: 'order_receipt',
      fiscalDocument: false,
      issuedAt: detail.order.placedAt ?? detail.order.createdAt,
      restaurant: {
        name: restaurant.name,
        vatNumber: restaurant.vatNumber ?? null,
        fiscalCode: restaurant.fiscalCode ?? null,
        address: [
          restaurant.addressLine1,
          restaurant.addressLine2,
          [restaurant.postalCode, restaurant.city].filter(Boolean).join(' '),
          restaurant.province,
        ].filter(Boolean),
        phone: restaurant.phone ?? null,
        email: restaurant.email ?? null,
      },
      order: {
        number: detail.order.orderNumber,
        type: detail.order.orderType,
        status: detail.order.status,
        paymentStatus: detail.order.paymentStatus,
        paymentMethod: detail.order.paymentMethod ?? null,
        currency: detail.order.currency,
        items: detail.items.map((item) => ({
          name: item.itemNameSnapshot,
          size: item.sizeNameSnapshot ?? null,
          quantity: item.quantity,
          unitPriceMinor: item.unitPriceMinor,
          lineTotalMinor: item.lineTotalMinor,
          options: detail.options
            .filter((option) => option.orderItemId === item.id)
            .map((option) => ({
              name: option.optionNameSnapshot,
              quantity: Number(option.quantity),
              totalPriceAdjustmentMinor: option.totalPriceAdjustmentMinor,
            })),
        })),
        totals: {
          subtotalMinor: detail.order.subtotalMinor,
          optionChargesMinor: detail.order.optionChargesMinor,
          discountMinor: detail.order.discountMinor,
          deliveryFeeMinor: detail.order.deliveryFeeMinor,
          taxMinor: detail.order.taxMinor,
          grandTotalMinor: detail.order.grandTotalMinor,
        },
      },
      notice:
        'Order receipt only. A fiscal document is issued by the configured fiscal provider when applicable.',
    };
  }

  async adminDetail(orderId: string, actorUserId: string) {
    const staff = requireEntity(
      await this.dataSource.getRepository(StaffMember).findOne({
        where: { userId: actorUserId, isActive: true },
      }),
      'Staff member not found',
    );
    const order = requireEntity(
      await this.orders.findOne({
        where: { id: orderId, restaurantId: staff.restaurantId },
      }),
      'Order not found',
    );
    const items = await this.dataSource.getRepository(OrderItem).find({
      where: { orderId },
      order: { createdAt: 'ASC' },
    });
    const options = items.length
      ? await this.dataSource
          .getRepository(OrderItemOption)
          .createQueryBuilder('option')
          .where('option.order_item_id IN (:...ids)', {
            ids: items.map((item) => item.id),
          })
          .getMany()
      : [];
    const statusHistory = await this.dataSource
      .getRepository(OrderStatusHistory)
      .find({ where: { orderId }, order: { occurredAt: 'ASC' } });
    return { order, items, options, statusHistory };
  }

  async reorder(customerId: string, orderId: string) {
    const detail = await this.customerDetail(customerId, orderId);
    const unavailable: Array<{
      orderItemId: string;
      itemName: string;
      reason: string;
    }> = [];
    const additions: AddCartItemDto[] = [];

    for (const item of detail.items) {
      if (!item.menuItemId) {
        unavailable.push({
          orderItemId: item.id,
          itemName: item.itemNameSnapshot,
          reason: 'Menu item no longer exists',
        });
        continue;
      }
      const options = detail.options
        .filter((option) => option.orderItemId === item.id)
        .map((option) => ({
          optionGroupId: option.optionGroupId,
          optionChoiceId: option.optionChoiceId,
          ingredientId: option.ingredientId,
          action: option.action as 'add' | 'remove' | 'replace',
          quantity: Number(option.quantity),
        }));
      const addition: AddCartItemDto = {
        menuItemId: item.menuItemId,
        menuItemSizeId: item.menuItemSizeId,
        quantity: item.quantity,
        options,
        specialInstructions: item.specialInstructions,
      };
      try {
        await this.pricing.calculate({
          menuItemId: addition.menuItemId,
          sizeId: addition.menuItemSizeId,
          quantity: addition.quantity,
          options,
        });
        additions.push(addition);
      } catch (error) {
        unavailable.push({
          orderItemId: item.id,
          itemName: item.itemNameSnapshot,
          reason:
            error instanceof Error
              ? error.message
              : 'Configuration is unavailable',
        });
      }
    }

    if (unavailable.length) {
      throw new UnprocessableEntityException({
        message: 'The order cannot be recreated with the current menu',
        unavailable,
      });
    }
    try {
      return await this.carts.addItemsAtomic(
        customerId,
        detail.order.restaurantId,
        additions,
      );
    } catch (error) {
      throw new UnprocessableEntityException({
        message: 'Order cannot be fully reordered',
        unavailableItems: [
          {
            orderItemId: null,
            menuItemId: null,
            reason: 'MENU_CHANGED_DURING_REORDER',
            details: [
              error instanceof Error ? error.message : 'Validation failed',
            ],
          },
        ],
      });
    }
  }

  async listAdmin(actorUserId: string, status?: string) {
    const staff = requireEntity(
      await this.dataSource.getRepository(StaffMember).findOne({
        where: { userId: actorUserId, isActive: true },
      }),
      'Staff member not found',
    );
    return this.orders.findMany({
      where: {
        restaurantId: staff.restaurantId,
        ...(status ? { status } : {}),
      } as any,
      order: { createdAt: 'DESC' },
    });
  }

  async updateAdminStatus(
    orderId: string,
    dto: UpdateOrderStatusDto,
    actorUserId: string,
  ): Promise<Order> {
    const staff = requireEntity(
      await this.dataSource.getRepository(StaffMember).findOne({
        where: { userId: actorUserId, isActive: true },
      }),
      'Staff member not found',
    );
    requireEntity(
      await this.orders.findOne({
        where: { id: orderId, restaurantId: staff.restaurantId },
      }),
      'Order not found',
    );
    return this.updateStatus(orderId, dto, actorUserId);
  }

  async updateStatus(
    orderId: string,
    dto: UpdateOrderStatusDto,
    actorUserId?: string,
  ): Promise<Order> {
    return this.dataSource.transaction(async (manager) => {
      const orderRepo = manager.getRepository(Order);
      const historyRepo = manager.getRepository(OrderStatusHistory);
      const order = requireEntity(
        await orderRepo
          .createQueryBuilder('order')
          .setLock('pessimistic_write')
          .where('order.id = :orderId', { orderId })
          .getOne(),
        'Order not found',
      );
      const current = String(order.status);
      const next = String(dto.status);
      const allowed = [...(TRANSITIONS[current] ?? [])];
      if (
        current === 'ready' &&
        ['pickup', 'dine_in', 'takeaway'].includes(String(order.orderType))
      ) {
        allowed.push('closed');
      }
      if (!allowed.includes(next)) {
        throw new BadRequestException(
          `Invalid order transition: ${current} -> ${next}`,
        );
      }
      const previous = order.status;
      order.status = dto.status as any;
      order.version = String(Number(order.version) + 1);
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
      await this.outbox.enqueue(manager, {
        aggregateType: 'order',
        aggregateId: saved.id,
        eventType: 'order.status_changed',
        payload: { orderId: saved.id, status: next },
      });
      return saved;
    });
  }

  async cancelByCustomer(customerId: string, orderId: string, reason?: string) {
    const { order } = await this.customerDetail(customerId, orderId);
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
