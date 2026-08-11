import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource, Not } from 'typeorm';
import { AdminListQueryDto } from '../../common/dto/admin-list-query.dto';
import { Order } from '../orders/entities/order.entity';
import { StaffMember } from '../staff/entities/staff-member.entity';
import { PaymentTransaction } from '../payments/entities/payment-transaction.entity';
import {
  PAYMENT_PROVIDER,
  PaymentProviderPort,
} from '../payments/interfaces/payment-provider.interface';
import { CreateRefundDto } from './dto/create-refund.dto';
import { Refund } from './entities/refund.entity';

@Injectable()
export class RefundsService {
  constructor(
    private readonly dataSource: DataSource,
    @Inject(PAYMENT_PROVIDER) private readonly provider: PaymentProviderPort,
  ) {}

  async create(actorUserId: string, dto: CreateRefundDto, isAdmin = false) {
    return this.dataSource.transaction(async (manager) => {
      const order = await this.ownedOrder(
        manager,
        actorUserId,
        dto.orderId,
        isAdmin,
        true,
      );
      const payment = await manager.getRepository(PaymentTransaction).findOne({
        where: { orderId: order.id, provider: 'sumup', status: Not('failed') },
        order: { createdAt: 'DESC' },
        lock: { mode: 'pessimistic_write' },
      });
      if (
        !payment ||
        !payment.providerTransactionId ||
        !['captured', 'partially_refunded'].includes(payment.status)
      ) {
        throw new BadRequestException(
          'Order does not have a refundable payment',
        );
      }
      const repo = manager.getRepository(Refund);
      const existing = await repo.findOne({
        where: {
          paymentTransactionId: payment.id,
          idempotencyKey: dto.idempotencyKey,
        },
      });
      if (existing) return existing;
      const committed = await repo
        .createQueryBuilder('refund')
        .select('COALESCE(SUM(refund.amountMinor), 0)', 'total')
        .where('refund.paymentTransactionId = :paymentId', {
          paymentId: payment.id,
        })
        .andWhere('refund.status IN (:...statuses)', {
          statuses: ['approved', 'processing', 'refunded'],
        })
        .getRawOne<{ total: string }>();
      if (
        Number(committed?.total ?? 0) + dto.amountMinor >
        payment.amountMinor
      ) {
        throw new ConflictException(
          'Refund amount exceeds the remaining refundable amount',
        );
      }
      return repo.save(
        repo.create({
          orderId: order.id,
          paymentTransactionId: payment.id,
          requestedByUserId: actorUserId,
          amountMinor: dto.amountMinor,
          reason: dto.reason,
          customerReason: dto.customerReason,
          idempotencyKey: dto.idempotencyKey,
          status: 'requested',
        }),
      );
    });
  }

  async listForOrder(actorUserId: string, orderId: string, isAdmin = false) {
    await this.ownedOrder(
      this.dataSource.manager,
      actorUserId,
      orderId,
      isAdmin,
    );
    return this.dataSource.getRepository(Refund).find({
      where: { orderId },
      order: { createdAt: 'DESC' },
    });
  }

  async listAdmin(actorUserId: string, query: AdminListQueryDto) {
    const staff = await this.dataSource.getRepository(StaffMember).findOne({
      where: { userId: actorUserId, isActive: true },
    });
    if (!staff) throw new NotFoundException('Staff member not found');
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? 20;
    const builder = this.dataSource
      .getRepository(Refund)
      .createQueryBuilder('refund')
      .innerJoinAndSelect('refund.order', 'order')
      .where('order.restaurant_id = :restaurantId', {
        restaurantId: staff.restaurantId,
      })
      .orderBy('refund.createdAt', 'DESC')
      .skip((page - 1) * pageSize)
      .take(pageSize);
    if (query.status)
      builder.andWhere('refund.status = :status', { status: query.status });
    const [data, total] = await builder.getManyAndCount();
    return {
      data,
      meta: { page, pageSize, total, totalPages: Math.ceil(total / pageSize) },
    };
  }

  async get(actorUserId: string, id: string, isAdmin = false) {
    const refund = await this.dataSource.getRepository(Refund).findOne({
      where: { id },
    });
    if (!refund) throw new NotFoundException('Refund not found');
    await this.ownedOrder(
      this.dataSource.manager,
      actorUserId,
      refund.orderId,
      isAdmin,
    );
    return refund;
  }

  private async ownedOrder(
    manager: Pick<DataSource, 'getRepository'>,
    actorUserId: string,
    orderId: string,
    isAdmin: boolean,
    lock = false,
  ) {
    if (!isAdmin) {
      const order = await manager.getRepository(Order).findOne({
        where: { id: orderId, customerId: actorUserId },
        ...(lock ? { lock: { mode: 'pessimistic_write' as const } } : {}),
      });
      if (!order) throw new NotFoundException('Order not found');
      return order;
    }
    const staff = await manager.getRepository(StaffMember).findOne({
      where: { userId: actorUserId, isActive: true },
    });
    if (!staff) throw new NotFoundException('Staff member not found');
    const order = await manager.getRepository(Order).findOne({
      where: { id: orderId, restaurantId: staff.restaurantId },
      ...(lock ? { lock: { mode: 'pessimistic_write' as const } } : {}),
    });
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  async approve(id: string, actorUserId: string, staffNote?: string) {
    let providerFailure = false;
    try {
      return await this.dataSource.transaction(async (manager) => {
        const repo = manager.getRepository(Refund);
        const refund = await repo.findOne({
          where: { id },
          lock: { mode: 'pessimistic_write' },
        });
        if (!refund) throw new NotFoundException('Refund not found');
        await this.ownedOrder(
          manager as unknown as Pick<DataSource, 'getRepository'>,
          actorUserId,
          refund.orderId,
          true,
        );
        if (refund.status === 'refunded') return refund;
        if (refund.status !== 'requested')
          throw new ConflictException(
            'Refund cannot be processed in its current state',
          );
        const payment = await manager
          .getRepository(PaymentTransaction)
          .findOne({
            where: { id: refund.paymentTransactionId },
            lock: { mode: 'pessimistic_write' },
          });
        if (!payment?.providerTransactionId)
          throw new BadRequestException('Provider transaction is unavailable');
        const totals = await repo
          .createQueryBuilder('other')
          .select('COALESCE(SUM(other.amountMinor), 0)', 'total')
          .where('other.paymentTransactionId = :paymentId', {
            paymentId: payment.id,
          })
          .andWhere('other.id <> :id', { id: refund.id })
          .andWhere('other.status IN (:...statuses)', {
            statuses: ['approved', 'processing', 'refunded'],
          })
          .getRawOne<{ total: string }>();
        if (
          Number(totals?.total ?? 0) + refund.amountMinor >
          payment.amountMinor
        ) {
          throw new ConflictException(
            'Refund amount exceeds the remaining refundable amount',
          );
        }
        refund.status = 'processing';
        refund.staffNote = staffNote;
        await repo.save(refund);
        try {
          const result = await this.provider.refundPayment(
            payment.providerTransactionId,
            refund.amountMinor,
          );
          refund.providerRefundId = result.providerRefundId;
          refund.status = result.status;
          refund.processedAt = new Date();
          await repo.save(refund);
          const refunded = Number(totals?.total ?? 0) + refund.amountMinor;
          payment.status =
            refunded === payment.amountMinor
              ? 'refunded'
              : 'partially_refunded';
          await manager.getRepository(PaymentTransaction).save(payment);
          const order = await manager.getRepository(Order).findOne({
            where: { id: payment.orderId },
            lock: { mode: 'pessimistic_write' },
          });
          if (order) {
            order.paymentStatus = payment.status;
            await manager.getRepository(Order).save(order);
          }
          return refund;
        } catch (error) {
          providerFailure = true;
          throw error;
        }
      });
    } catch (error) {
      if (providerFailure) {
        await this.dataSource
          .getRepository(Refund)
          .update(
            { id },
            { status: 'failed', processedAt: new Date(), staffNote },
          );
      }
      throw error;
    }
  }
}
