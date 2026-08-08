import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash, randomUUID } from 'crypto';
import { DataSource, EntityManager } from 'typeorm';
import { requireEntity } from '../../common/utils/service-errors.util';
import { OutboxService } from '../../queue/outbox.service';
import { OrderItem } from '../orders/entities/order-item.entity';
import { OrderStatusHistory } from '../orders/entities/order-status-history.entity';
import { Order } from '../orders/entities/order.entity';
import { DeliveryAssignment } from '../deliveries/entities/delivery-assignment.entity';
import { CollectPaymentDto } from './dto/collect-payment.dto';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { SumUpWebhookDto } from './dto/sumup-webhook.dto';
import { CustomerPaymentMethod } from './entities/customer-payment-method.entity';
import { PaymentReceipt } from './entities/payment-receipt.entity';
import { PaymentTransaction } from './entities/payment-transaction.entity';
import { PaymentWebhookEvent } from './entities/payment-webhook-event.entity';
import {
  PAYMENT_PROVIDER,
  PaymentProviderPort,
  ProviderCheckout,
} from './interfaces/payment-provider.interface';
import { PaymentTransactionRepository } from './repositories/payment-transaction.repository';

@Injectable()
export class PaymentsService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly transactions: PaymentTransactionRepository,
    private readonly config: ConfigService,
    private readonly outbox: OutboxService,
    @Inject(PAYMENT_PROVIDER) private readonly provider: PaymentProviderPort,
  ) {}

  listMethods(customerId: string) {
    return this.dataSource.getRepository(CustomerPaymentMethod).find({
      where: { customerId, archivedAt: null as any },
      order: { isDefault: 'DESC', createdAt: 'DESC' },
    });
  }

  async createCheckout(customerId: string, dto: CreatePaymentIntentDto) {
    return this.dataSource.transaction(async (manager) => {
      const order = requireEntity(
        await manager.getRepository(Order).findOne({
          where: { id: dto.orderId, customerId },
          lock: { mode: 'pessimistic_write' },
        }),
        'Order not found',
      );
      if (order.paymentMethod !== 'card') {
        throw new BadRequestException(
          'Order is not configured for online payment',
        );
      }
      if (order.paymentStatus === 'paid') {
        throw new ConflictException('Order is already paid');
      }

      const key = dto.idempotencyKey ?? randomUUID();
      const requestHash = createHash('sha256')
        .update(
          JSON.stringify({
            orderId: order.id,
            amountMinor: order.grandTotalMinor,
            currency: order.currency,
          }),
        )
        .digest('hex');
      const repo = manager.getRepository(PaymentTransaction);
      const existing = await repo.findOne({
        where: { orderId: order.id, idempotencyKey: key },
      });
      if (existing) {
        if (existing.requestHash !== requestHash) {
          throw new ConflictException(
            'Idempotency key was used for another payment request',
          );
        }
        return this.safeTransaction(existing);
      }

      const transaction = await repo.save(
        repo.create({
          orderId: order.id,
          customerId,
          provider: 'sumup',
          paymentMethodType: 'card',
          amountMinor: Number(order.grandTotalMinor),
          currency: 'EUR',
          status: 'pending',
          idempotencyKey: key,
          requestHash,
          checkoutReference: `LF-${order.orderNumber}-${randomUUID()}`.slice(
            0,
            90,
          ),
          metadata: { orderNumber: order.orderNumber },
        }),
      );

      const checkout = await this.provider.createCheckout({
        checkoutReference: transaction.checkoutReference!,
        amountMinor: transaction.amountMinor,
        currency: 'EUR',
        description: `La Favola order ${order.orderNumber}`,
      });
      this.assertProviderIdentity(transaction, checkout);
      transaction.providerCheckoutId = checkout.checkoutId;
      transaction.providerTransactionId = checkout.transactionId;
      transaction.providerPaymentIntentId = checkout.checkoutId;
      transaction.status = checkout.status;
      transaction.metadata = {
        ...transaction.metadata,
        hostedCheckoutUrl: checkout.hostedCheckoutUrl,
        providerTransactionCode: checkout.transactionCode,
      };
      await repo.save(transaction);
      return this.safeTransaction(transaction);
    });
  }

  async getOrderPaymentStatus(
    customerId: string,
    orderId: string,
    refresh = true,
  ) {
    const transaction = requireEntity(
      await this.transactions.findOne({
        where: { orderId, customerId, provider: 'sumup' },
        order: { createdAt: 'DESC' },
      }),
      'Payment not found',
    );
    if (
      refresh &&
      transaction.providerCheckoutId &&
      ['pending', 'requires_action'].includes(transaction.status)
    ) {
      const checkout = await this.provider.getCheckout(
        transaction.providerCheckoutId,
      );
      await this.synchronizeCheckout(checkout);
      return this.safeTransaction(
        requireEntity(
          await this.transactions.findById(transaction.id),
          'Payment not found',
        ),
      );
    }
    return this.safeTransaction(transaction);
  }

  async handleSumUpWebhook(dto: SumUpWebhookDto) {
    if (dto.eventType !== 'CHECKOUT_STATUS_CHANGED') return;
    const checkout = await this.provider.getCheckout(dto.id);
    await this.synchronizeCheckout(checkout, dto.eventType);
  }

  async synchronizeCheckout(
    checkout: ProviderCheckout,
    eventType = 'CHECKOUT_STATUS_REFRESHED',
  ) {
    await this.dataSource.transaction(async (manager) => {
      const repo = manager.getRepository(PaymentTransaction);
      const transaction = await repo.findOne({
        where: { provider: 'sumup', providerCheckoutId: checkout.checkoutId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!transaction)
        throw new NotFoundException('Payment checkout is unknown');
      this.assertProviderIdentity(transaction, checkout);

      const eventRepo = manager.getRepository(PaymentWebhookEvent);
      const eventId = `${checkout.checkoutId}:${checkout.status}`;
      if (
        await eventRepo.findOne({
          where: { provider: 'sumup', providerEventId: eventId },
        })
      )
        return;
      const event = await eventRepo.save(
        eventRepo.create({
          provider: 'sumup',
          providerEventId: eventId,
          eventType,
          payload: {
            checkoutId: checkout.checkoutId,
            verifiedStatus: checkout.status,
          },
          processingStatus: 'pending',
          attempts: 1,
        }),
      );

      if (this.isStale(transaction.status, checkout.status)) {
        event.processingStatus = 'ignored';
        event.processedAt = new Date();
        await eventRepo.save(event);
        return;
      }
      transaction.status = checkout.status;
      transaction.providerTransactionId =
        checkout.transactionId ?? transaction.providerTransactionId;
      if (checkout.status === 'captured')
        transaction.capturedAt = transaction.capturedAt ?? new Date();
      if (checkout.status === 'failed')
        transaction.failedAt = transaction.failedAt ?? new Date();
      await repo.save(transaction);

      const order = requireEntity(
        await manager.getRepository(Order).findOne({
          where: { id: transaction.orderId },
          lock: { mode: 'pessimistic_write' },
        }),
        'Order not found',
      );
      if (checkout.status === 'captured') {
        order.paymentStatus = 'paid';
        if (order.status === 'pending_payment') {
          order.status = 'placed';
          order.placedAt = order.placedAt ?? new Date();
          await manager.getRepository(OrderStatusHistory).save(
            manager.getRepository(OrderStatusHistory).create({
              orderId: order.id,
              previousStatus: 'pending_payment',
              newStatus: 'placed',
              note: 'SumUp payment verified',
            }),
          );
          await this.outbox.enqueue(manager, {
            aggregateType: 'order',
            aggregateId: order.id,
            eventType: 'order.confirmed',
            payload: { orderId: order.id },
          });
        }
        await manager.getRepository(Order).save(order);
        await this.ensureReceipt(manager, order, transaction);
      } else if (
        ['failed', 'cancelled'].includes(checkout.status) &&
        order.paymentStatus !== 'paid'
      ) {
        order.paymentStatus = checkout.status;
        await manager.getRepository(Order).save(order);
      }
      event.processingStatus = 'processed';
      event.processedAt = new Date();
      await eventRepo.save(event);
    });
  }

  async collectOnDelivery(
    orderId: string,
    collectorUserId: string,
    dto: CollectPaymentDto,
    isAdmin = false,
  ) {
    return this.dataSource.transaction(async (manager) => {
      const order = requireEntity(
        await manager.getRepository(Order).findOne({
          where: { id: orderId },
          lock: { mode: 'pessimistic_write' },
        }),
        'Order not found',
      );
      if (!['cash', 'card_on_delivery'].includes(String(order.paymentMethod))) {
        throw new BadRequestException(
          'Order is not configured for pay-on-delivery',
        );
      }
      if (dto.orderId !== orderId)
        throw new BadRequestException('Order identifier does not match route');
      if (dto.paymentMethodType !== order.paymentMethod)
        throw new BadRequestException(
          'Collection method does not match the order',
        );
      if (!isAdmin) {
        const assignment = await manager
          .getRepository(DeliveryAssignment)
          .findOne({ where: { orderId, driverUserId: collectorUserId } });
        if (
          !assignment ||
          !['accepted', 'picked_up', 'en_route', 'arriving'].includes(
            assignment.status,
          )
        )
          throw new NotFoundException('Delivery assignment not found');
      }
      if (order.paymentStatus === 'paid')
        throw new ConflictException('Order is already paid');
      const repo = manager.getRepository(PaymentTransaction);
      const transaction = await repo.save(
        repo.create({
          orderId: order.id,
          customerId: order.customerId,
          provider:
            dto.paymentMethodType === 'cash' ? 'cash' : 'external_terminal',
          paymentMethodType: dto.paymentMethodType,
          amountMinor: Number(order.grandTotalMinor),
          currency: 'EUR',
          status: 'captured',
          idempotencyKey: dto.idempotencyKey,
          capturedAt: new Date(),
          metadata: { collectorUserId },
        }),
      );
      order.paymentStatus = 'paid';
      await manager.getRepository(Order).save(order);
      await this.ensureReceipt(manager, order, transaction);
      return this.safeTransaction(transaction);
    });
  }

  private assertProviderIdentity(
    transaction: PaymentTransaction,
    checkout: ProviderCheckout,
  ) {
    if (
      checkout.checkoutReference !== transaction.checkoutReference ||
      checkout.merchantCode !==
        this.config.getOrThrow<string>('SUMUP_MERCHANT_CODE') ||
      checkout.amountMinor !== transaction.amountMinor ||
      checkout.currency !== transaction.currency
    )
      throw new UnprocessableEntityException(
        'Payment provider verification failed',
      );
  }

  private isStale(current: string, next: string) {
    const terminal = ['captured', 'refunded'];
    return terminal.includes(current) && current !== next;
  }

  private async ensureReceipt(
    manager: EntityManager,
    order: Order,
    transaction: PaymentTransaction,
  ) {
    const repo = manager.getRepository(PaymentReceipt);
    if (await repo.findOne({ where: { paymentTransactionId: transaction.id } }))
      return;
    const items = await manager
      .getRepository(OrderItem)
      .find({ where: { orderId: order.id } });
    await repo.save(
      repo.create({
        orderId: order.id,
        paymentTransactionId: transaction.id,
        receiptNumber: `LF-R-${order.orderNumber}-${transaction.id.slice(0, 8)}`,
        amountMinor: Number(order.grandTotalMinor),
        taxMinor: Number(order.taxMinor),
        currency: 'EUR',
        receiptData: {
          orderNumber: order.orderNumber,
          paymentMethod: transaction.paymentMethodType,
          items: items.map((item) => ({
            name: item.itemNameSnapshot,
            quantity: item.quantity,
            lineTotalMinor: item.lineTotalMinor,
          })),
        },
      }),
    );
  }

  private safeTransaction(transaction: PaymentTransaction) {
    return {
      id: transaction.id,
      orderId: transaction.orderId,
      status: transaction.status,
      amountMinor: transaction.amountMinor,
      currency: transaction.currency,
      checkoutId: transaction.providerCheckoutId,
      hostedCheckoutUrl: transaction.metadata?.hostedCheckoutUrl,
    };
  }
}
