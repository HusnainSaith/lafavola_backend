import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { createHash } from 'crypto';
import { DataSource, In, IsNull } from 'typeorm';
import { requireEntity } from '../../common/utils/service-errors.util';
import { OutboxService } from '../../queue/outbox.service';
import { IdempotencyKey } from '../audit/entities/idempotency-key.entity';
import { MenuCategory } from '../categories/entities/menu-category.entity';
import { Ingredient } from '../ingredients/entities/ingredient.entity';
import { MenuItemSize } from '../menu/entities/menu-item-size.entity';
import { MenuItem } from '../menu/entities/menu-item.entity';
import { MenuItemOptionGroup } from '../option-groups/entities/menu-item-option-group.entity';
import { OptionChoice } from '../option-groups/entities/option-choice.entity';
import { OptionGroup } from '../option-groups/entities/option-group.entity';
import { OrderItemOption } from '../orders/entities/order-item-option.entity';
import { OrderItem } from '../orders/entities/order-item.entity';
import { OrderStatusHistory } from '../orders/entities/order-status-history.entity';
import { Order } from '../orders/entities/order.entity';
import { CollectPaymentDto } from '../payments/dto/collect-payment.dto';
import { PaymentReceipt } from '../payments/entities/payment-receipt.entity';
import { PaymentsService } from '../payments/payments.service';
import { OrderTotalsService } from '../pricing/order-totals.service';
import { PricingService } from '../pricing/pricing.service';
import { Restaurant } from '../restaurants/entities/restaurant.entity';
import { StaffMember } from '../staff/entities/staff-member.entity';
import { CreatePosOrderDto } from './dto/create-pos-order.dto';
import { ListPosReceiptsDto } from './dto/list-pos-receipts.dto';

@Injectable()
export class AdminPosService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly pricing: PricingService,
    private readonly totals: OrderTotalsService,
    private readonly payments: PaymentsService,
    private readonly outbox: OutboxService,
  ) {}

  async catalog(actorUserId: string) {
    const staff = await this.activeStaff(actorUserId);
    const now = new Date();
    const categories = await this.dataSource.getRepository(MenuCategory).find({
      where: { restaurantId: staff.restaurantId, isActive: true },
      order: { displayOrder: 'ASC', createdAt: 'ASC' },
    });
    const items = await this.dataSource.getRepository(MenuItem).find({
      where: {
        restaurantId: staff.restaurantId,
        isActive: true,
        archivedAt: IsNull(),
      },
      relations: { sizes: true, imageAsset: true },
      order: { popularityScore: 'DESC', createdAt: 'ASC' },
    });
    const availableItems = items.filter(
      (item) =>
        (!item.availableFrom || item.availableFrom <= now) &&
        (!item.availableUntil || item.availableUntil > now),
    );
    const itemIds = availableItems.map((item) => item.id);
    const mappings = itemIds.length
      ? await this.dataSource.getRepository(MenuItemOptionGroup).find({
          where: { menuItemId: In(itemIds) },
          order: { displayOrder: 'ASC' },
        })
      : [];
    const groupIds = [...new Set(mappings.map((entry) => entry.optionGroupId))];
    const groups = groupIds.length
      ? await this.dataSource.getRepository(OptionGroup).find({
          where: {
            id: In(groupIds),
            restaurantId: staff.restaurantId,
            isActive: true,
          },
          order: { displayOrder: 'ASC' },
        })
      : [];
    const activeGroupIds = groups.map((group) => group.id);
    const choices = activeGroupIds.length
      ? await this.dataSource.getRepository(OptionChoice).find({
          where: { optionGroupId: In(activeGroupIds), isActive: true },
          order: { displayOrder: 'ASC', createdAt: 'ASC' },
        })
      : [];

    return {
      restaurantId: staff.restaurantId,
      categories,
      items: availableItems.map((item) => ({
        ...item,
        sizes: item.sizes
          .filter((size) => size.isActive)
          .sort((a, b) => a.displayOrder - b.displayOrder),
        optionGroups: mappings
          .filter((entry) => entry.menuItemId === item.id)
          .map((entry) => {
            const group = groups.find(
              (candidate) => candidate.id === entry.optionGroupId,
            );
            if (!group) return null;
            return {
              ...group,
              minSelect: entry.minSelectOverride ?? group.minSelect,
              maxSelect: entry.maxSelectOverride ?? group.maxSelect,
              choices: choices.filter(
                (choice) => choice.optionGroupId === group.id,
              ),
            };
          })
          .filter(Boolean),
      })),
    };
  }

  async createOrder(actorUserId: string, dto: CreatePosOrderDto) {
    this.validateServiceMode(dto);
    const staff = await this.activeStaff(actorUserId);
    const restaurant = requireEntity(
      await this.dataSource.getRepository(Restaurant).findOne({
        where: { id: staff.restaurantId, isActive: true },
      }),
      'La Favola Restaurant is not configured',
    );
    const keyHash = createHash('sha256')
      .update(dto.idempotencyKey)
      .digest('hex');
    const requestHash = createHash('sha256')
      .update(JSON.stringify(dto))
      .digest('hex');
    const previous = await this.dataSource
      .getRepository(IdempotencyKey)
      .findOne({
        where: { actorUserId, scope: 'admin_pos_order', keyHash },
      });
    if (previous) {
      if (previous.requestHash !== requestHash) {
        throw new ConflictException(
          'Idempotency key was already used for a different POS order',
        );
      }
      if (previous.responseBody) return previous.responseBody;
      throw new ConflictException('POS order creation is already in progress');
    }

    const prepared = [] as Array<{
      input: CreatePosOrderDto['items'][number];
      item: MenuItem;
      size: MenuItemSize;
      pricing: Awaited<ReturnType<PricingService['calculate']>>;
      options: Array<{
        optionGroupId?: string;
        optionChoiceId?: string;
        ingredientId?: string;
        action: string;
        name: string;
        quantity: number;
        unitPriceAdjustmentMinor: number;
      }>;
    }>;

    for (const input of dto.items) {
      const [price, item, size] = await Promise.all([
        this.pricing.calculate({
          menuItemId: input.menuItemId,
          sizeId: input.sizeId,
          quantity: input.quantity,
          options: input.options as never,
        }),
        this.dataSource.getRepository(MenuItem).findOne({
          where: {
            id: input.menuItemId,
            restaurantId: staff.restaurantId,
            isActive: true,
          },
        }),
        this.dataSource.getRepository(MenuItemSize).findOne({
          where: {
            id: input.sizeId,
            menuItemId: input.menuItemId,
            isActive: true,
          },
        }),
      ]);
      if (!item || !size)
        throw new NotFoundException('Menu item is unavailable');
      const choiceIds = (input.options ?? [])
        .map((option) => option.optionChoiceId)
        .filter((id): id is string => Boolean(id));
      const ingredientIds = (input.options ?? [])
        .map((option) => option.ingredientId)
        .filter((id): id is string => Boolean(id));
      const [choices, ingredients] = await Promise.all([
        choiceIds.length
          ? this.dataSource.getRepository(OptionChoice).find({
              where: { id: In(choiceIds), isActive: true },
            })
          : [],
        ingredientIds.length
          ? this.dataSource.getRepository(Ingredient).find({
              where: {
                id: In(ingredientIds),
                restaurantId: staff.restaurantId,
              },
            })
          : [],
      ]);
      prepared.push({
        input,
        item,
        size,
        pricing: price,
        options: (input.options ?? []).map((option) => {
          const choice = choices.find(
            (candidate) => candidate.id === option.optionChoiceId,
          );
          const ingredient = ingredients.find(
            (candidate) => candidate.id === option.ingredientId,
          );
          return {
            optionGroupId: option.optionGroupId,
            optionChoiceId: option.optionChoiceId,
            ingredientId: option.ingredientId,
            action: option.action ?? 'add',
            name: choice?.name ?? ingredient?.name ?? 'Personalizzazione',
            quantity: option.quantity ?? 1,
            unitPriceAdjustmentMinor: choice
              ? Number(choice.priceAdjustmentMinor)
              : 0,
          };
        }),
      });
    }

    const subtotalMinor = prepared.reduce(
      (sum, line) =>
        sum + Number(line.pricing.basePriceMinor) * line.input.quantity,
      0,
    );
    const optionChargesMinor = prepared.reduce(
      (sum, line) =>
        sum + Number(line.pricing.optionAdjustmentsMinor) * line.input.quantity,
      0,
    );
    const totals = this.totals.calculate({
      subtotalMinor,
      optionChargesMinor,
      deliveryFeeMinor: 0,
      promotionDiscountMinor: 0,
      couponDiscountMinor: 0,
      loyaltyDiscountMinor: 0,
      deliveryDiscountMinor: 0,
      taxRateBasisPoints: Number(restaurant.taxRateBasisPoints ?? 0),
      taxExcluded: restaurant.taxBehavior === 'excluded',
    });

    return this.dataSource.transaction(async (manager) => {
      const key = await manager.getRepository(IdempotencyKey).save(
        manager.getRepository(IdempotencyKey).create({
          actorUserId,
          scope: 'admin_pos_order',
          keyHash,
          requestHash,
          lockedUntil: new Date(Date.now() + 60_000),
          expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
        }),
      );
      const now = new Date();
      const order = await manager.getRepository(Order).save(
        manager.getRepository(Order).create({
          restaurantId: restaurant.id,
          orderType: dto.orderType,
          status: 'placed',
          paymentStatus: 'collection_pending',
          paymentMethod: dto.paymentMethod,
          currency: 'EUR',
          subtotalMinor,
          optionChargesMinor,
          discountMinor: 0,
          promotionDiscountMinor: 0,
          couponDiscountMinor: 0,
          loyaltyDiscountMinor: 0,
          deliveryFeeMinor: 0,
          taxMinor: totals.taxMinor,
          grandTotalMinor: totals.grandTotalMinor,
          customerNote: dto.customerNote?.trim() || undefined,
          tableLabel:
            dto.orderType === 'dine_in' ? dto.tableLabel?.trim() : undefined,
          walkInCustomerName: dto.customerName?.trim() || undefined,
          walkInCustomerPhone: dto.customerPhone?.trim() || undefined,
          createdByStaffUserId: actorUserId,
          placedAt: now,
          pricingSnapshot: {
            source: 'admin_pos',
            taxBehavior: restaurant.taxBehavior,
            taxRateBasisPoints: restaurant.taxRateBasisPoints,
          },
          version: '1',
        }),
      );

      const createdItems: OrderItem[] = [];
      for (const line of prepared) {
        const orderItem = await manager.getRepository(OrderItem).save(
          manager.getRepository(OrderItem).create({
            orderId: order.id,
            menuItemId: line.item.id,
            menuItemSizeId: line.size.id,
            itemNameSnapshot: line.item.name,
            sizeNameSnapshot: line.size.displayName,
            quantity: line.input.quantity,
            baseUnitPriceMinor: line.pricing.basePriceMinor,
            optionsUnitPriceMinor: line.pricing.optionAdjustmentsMinor,
            unitPriceMinor: line.pricing.unitPriceMinor,
            lineTotalMinor: line.pricing.lineTotalMinor,
            specialInstructions:
              line.input.specialInstructions?.trim() || undefined,
            configurationSnapshot: {
              source: 'admin_pos',
              options: line.input.options ?? [],
            },
          }),
        );
        createdItems.push(orderItem);
        if (line.options.length) {
          await manager.getRepository(OrderItemOption).save(
            line.options.map((option) =>
              manager.getRepository(OrderItemOption).create({
                orderItemId: orderItem.id,
                optionGroupId: option.optionGroupId,
                optionChoiceId: option.optionChoiceId,
                ingredientId: option.ingredientId,
                action: option.action,
                optionNameSnapshot: option.name,
                quantity: String(option.quantity),
                unitPriceAdjustmentMinor: option.unitPriceAdjustmentMinor,
                totalPriceAdjustmentMinor:
                  option.unitPriceAdjustmentMinor * option.quantity,
              }),
            ),
          );
        }
      }
      await manager.getRepository(OrderStatusHistory).save(
        manager.getRepository(OrderStatusHistory).create({
          orderId: order.id,
          newStatus: 'placed',
          changedByUserId: actorUserId,
          note: `Walk-in ${dto.orderType} order created from admin POS`,
        }),
      );
      await this.outbox.enqueue(manager, {
        aggregateType: 'order',
        aggregateId: order.id,
        eventType: 'order.placed',
        payload: { orderId: order.id, source: 'admin_pos' },
      });
      const response = { order, items: createdItems };
      key.responseStatus = 201;
      key.responseBody = response as unknown as Record<string, unknown>;
      key.lockedUntil = undefined;
      await manager.getRepository(IdempotencyKey).save(key);
      return response;
    });
  }

  async collect(actorUserId: string, orderId: string, dto: CollectPaymentDto) {
    const scoped = await this.assertOrder(actorUserId, orderId);
    if (!['dine_in', 'takeaway'].includes(scoped.order.orderType)) {
      throw new NotFoundException('Walk-in order not found');
    }
    const payment = await this.payments.collectOnDelivery(
      orderId,
      actorUserId,
      dto,
      true,
    );
    return { payment, receipt: await this.receipt(actorUserId, orderId) };
  }

  async receipt(actorUserId: string, orderId: string) {
    const { order, restaurant } = await this.assertOrder(actorUserId, orderId);
    const items = await this.dataSource.getRepository(OrderItem).find({
      where: { orderId },
      order: { createdAt: 'ASC' },
    });
    const options = items.length
      ? await this.dataSource.getRepository(OrderItemOption).find({
          where: { orderItemId: In(items.map((item) => item.id)) },
          order: { createdAt: 'ASC' },
        })
      : [];
    const paymentReceipt = await this.dataSource
      .getRepository(PaymentReceipt)
      .findOne({
        where: { orderId },
        relations: { paymentTransaction: true },
        order: { issuedAt: 'DESC' },
      });
    return {
      documentType: paymentReceipt ? 'payment_receipt' : 'order_ticket',
      documentNumber: paymentReceipt?.receiptNumber ?? order.orderNumber,
      issuedAt: paymentReceipt?.issuedAt ?? order.createdAt,
      fiscalDocument: false,
      fiscalNotice: 'COPIA DI CORTESIA - NON FISCALE',
      restaurant: {
        name: restaurant.name,
        phone: restaurant.phone,
        email: restaurant.email,
        vatNumber: restaurant.vatNumber,
        fiscalCode: restaurant.fiscalCode,
        addressLine1: restaurant.addressLine1,
        addressLine2: restaurant.addressLine2,
        city: restaurant.city,
        province: restaurant.province,
        postalCode: restaurant.postalCode,
      },
      order: {
        id: order.id,
        orderNumber: order.orderNumber,
        orderType: order.orderType,
        tableLabel: order.tableLabel,
        customerName: order.walkInCustomerName,
        customerPhone: order.walkInCustomerPhone,
        customerNote: order.customerNote,
        status: order.status,
        paymentStatus: order.paymentStatus,
        paymentMethod: order.paymentMethod,
        currency: order.currency,
        subtotalMinor: order.subtotalMinor,
        optionChargesMinor: order.optionChargesMinor,
        discountMinor: order.discountMinor,
        taxMinor: order.taxMinor,
        grandTotalMinor: order.grandTotalMinor,
        createdAt: order.createdAt,
      },
      items: items.map((item) => ({
        name: item.itemNameSnapshot,
        size: item.sizeNameSnapshot,
        quantity: item.quantity,
        unitPriceMinor: item.unitPriceMinor,
        lineTotalMinor: item.lineTotalMinor,
        specialInstructions: item.specialInstructions,
        options: options
          .filter((option) => option.orderItemId === item.id)
          .map((option) => ({
            name: option.optionNameSnapshot,
            action: option.action,
            quantity: Number(option.quantity),
            priceAdjustmentMinor: option.totalPriceAdjustmentMinor,
          })),
      })),
    };
  }

  async listReceipts(actorUserId: string, query: ListPosReceiptsDto) {
    const staff = await this.activeStaff(actorUserId);
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const [data, total] = await this.dataSource
      .getRepository(PaymentReceipt)
      .createQueryBuilder('receipt')
      .innerJoinAndSelect('receipt.order', 'order')
      .leftJoinAndSelect('receipt.paymentTransaction', 'payment')
      .where('order.restaurant_id = :restaurantId', {
        restaurantId: staff.restaurantId,
      })
      .orderBy('receipt.issuedAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();
    // Avoid the generic response interceptor treating this domain payload as
    // an already-wrapped response and dropping the pagination metadata.
    return {
      items: data,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  private validateServiceMode(dto: CreatePosOrderDto) {
    if (dto.orderType === 'dine_in' && !dto.tableLabel?.trim()) {
      throw new BadRequestException('A table label is required for dine-in');
    }
    if (dto.orderType === 'takeaway' && dto.tableLabel !== undefined) {
      throw new BadRequestException(
        'Takeaway orders cannot have a table label',
      );
    }
  }

  private async activeStaff(actorUserId: string) {
    return requireEntity(
      await this.dataSource.getRepository(StaffMember).findOne({
        where: { userId: actorUserId, isActive: true },
      }),
      'Staff member not found',
    );
  }

  private async assertOrder(actorUserId: string, orderId: string) {
    const staff = await this.activeStaff(actorUserId);
    const order = requireEntity(
      await this.dataSource.getRepository(Order).findOne({
        where: { id: orderId, restaurantId: staff.restaurantId },
      }),
      'Order not found',
    );
    const restaurant = requireEntity(
      await this.dataSource.getRepository(Restaurant).findOne({
        where: { id: staff.restaurantId },
      }),
      'La Favola Restaurant is not configured',
    );
    return { order, restaurant };
  }
}
