import {
  BadRequestException,
  ConflictException,
  Injectable,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { requireEntity } from '../../common/utils/service-errors.util';
import { Order } from '../orders/entities/order.entity';
import { AssignDriverDto } from './dto/assign-driver.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { DeliveryAssignment } from './entities/delivery-assignment.entity';
import { DeliveryTrackingEvent } from './entities/delivery-tracking-event.entity';
import { DeliveryTracking } from './entities/delivery-tracking.entity';
import { DeliveryTrackingRepository } from './repositories/delivery-tracking.repository';
import { DeliveryAssignmentStatus } from './enums/delivery-assignment-status.enum';
import { OutboxService } from '../../queue/outbox.service';
import { OrderStatusHistory } from '../orders/entities/order-status-history.entity';

const DELIVERY_TRANSITIONS: Record<string, DeliveryAssignmentStatus[]> = {
  assigned: [
    DeliveryAssignmentStatus.ACCEPTED,
    DeliveryAssignmentStatus.CANCELLED,
  ],
  accepted: [
    DeliveryAssignmentStatus.PICKED_UP,
    DeliveryAssignmentStatus.FAILED,
    DeliveryAssignmentStatus.CANCELLED,
  ],
  picked_up: [DeliveryAssignmentStatus.EN_ROUTE],
  en_route: [
    DeliveryAssignmentStatus.ARRIVING,
    DeliveryAssignmentStatus.DELIVERED,
    DeliveryAssignmentStatus.FAILED,
  ],
  arriving: [
    DeliveryAssignmentStatus.DELIVERED,
    DeliveryAssignmentStatus.FAILED,
  ],
  delivered: [],
  failed: [],
  cancelled: [],
};

@Injectable()
export class DeliveriesService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly tracking: DeliveryTrackingRepository,
    private readonly outbox: OutboxService,
  ) {}

  async getTracking(customerId: string, orderId: string) {
    requireEntity(
      await this.dataSource.getRepository(Order).findOne({
        where: { id: orderId, customerId },
      }),
      'Delivery tracking not found',
    );
    return requireEntity(
      await this.tracking.findByOrderId(orderId),
      'Delivery tracking not found',
    );
  }

  async assign(
    orderId: string,
    assignedByUserId: string,
    dto: AssignDriverDto,
  ) {
    return this.dataSource.transaction(async (manager) => {
      const assignmentRepo = manager.getRepository(DeliveryAssignment);
      const trackingRepo = manager.getRepository(DeliveryTracking);

      const order = requireEntity(
        await manager.getRepository(Order).findOne({
          where: { id: orderId },
          lock: { mode: 'pessimistic_write' },
        }),
        'Order not found',
      );
      if (!['ready', 'driver_assigned'].includes(String(order.status)))
        throw new BadRequestException('Order is not ready for delivery');

      let assignment = await assignmentRepo.findOne({ where: { orderId } });
      if (!assignment) {
        assignment = assignmentRepo.create({
          orderId,
          driverUserId: dto.driverUserId,
          assignedByUserId,
          status: 'assigned',
        });
      } else {
        assignment.driverUserId = dto.driverUserId;
        assignment.assignedByUserId = assignedByUserId;
        assignment.status = 'assigned' as any;
        assignment.assignedAt = new Date();
      }
      assignment = await assignmentRepo.save(assignment);

      let tracking = await trackingRepo.findOne({ where: { orderId } });
      if (!tracking) {
        tracking = trackingRepo.create({
          orderId,
          assignmentId: assignment.id,
          status: 'driver_assigned',
        });
      } else {
        tracking.assignmentId = assignment.id;
        tracking.status = 'driver_assigned' as any;
      }
      await trackingRepo.save(tracking);
      if (order.status === 'ready') {
        await this.updateOrderStatus(
          manager,
          order,
          'driver_assigned',
          assignedByUserId,
        );
      }
      await this.outbox.enqueue(manager, {
        aggregateType: 'delivery',
        aggregateId: assignment.id,
        eventType: 'delivery.assigned',
        payload: { orderId, assignmentId: assignment.id },
      });
      return assignment;
    });
  }

  assignmentForDriver(driverUserId: string, orderId: string, isAdmin = false) {
    return this.dataSource.getRepository(DeliveryAssignment).findOneOrFail({
      where: isAdmin ? { orderId } : { orderId, driverUserId },
    });
  }

  async transition(
    orderId: string,
    next: DeliveryAssignmentStatus,
    actorUserId: string,
    isAdmin = false,
  ) {
    return this.dataSource.transaction(async (manager) => {
      const assignment = requireEntity(
        await manager
          .getRepository(DeliveryAssignment)
          .createQueryBuilder('assignment')
          .setLock('pessimistic_write')
          .where('assignment.order_id=:orderId', { orderId })
          .getOne(),
        'Delivery assignment not found',
      );
      if (!isAdmin && assignment.driverUserId !== actorUserId)
        throw new BadRequestException('Delivery assignment not found');
      if (assignment.status === next) return assignment;
      if (!(DELIVERY_TRANSITIONS[assignment.status] ?? []).includes(next))
        throw new ConflictException(
          `Invalid delivery transition: ${assignment.status} -> ${next}`,
        );

      const tracking = requireEntity(
        await manager.getRepository(DeliveryTracking).findOne({
          where: { orderId },
          lock: { mode: 'pessimistic_write' },
        }),
        'Delivery tracking not found',
      );
      const order = requireEntity(
        await manager.getRepository(Order).findOne({
          where: { id: orderId },
          lock: { mode: 'pessimistic_write' },
        }),
        'Order not found',
      );
      if (
        next === DeliveryAssignmentStatus.DELIVERED &&
        ['cash', 'card_on_delivery'].includes(String(order.paymentMethod)) &&
        order.paymentStatus !== 'paid'
      )
        throw new ConflictException(
          'Pay-on-delivery collection must be recorded before delivery',
        );
      assignment.status = next;
      if (next === DeliveryAssignmentStatus.ACCEPTED)
        assignment.acceptedAt = new Date();
      if (next === DeliveryAssignmentStatus.PICKED_UP)
        assignment.pickedUpAt = new Date();
      if (
        [
          DeliveryAssignmentStatus.DELIVERED,
          DeliveryAssignmentStatus.FAILED,
          DeliveryAssignmentStatus.CANCELLED,
        ].includes(next)
      )
        assignment.completedAt = new Date();
      tracking.status =
        next === DeliveryAssignmentStatus.PICKED_UP
          ? 'en_route'
          : next === DeliveryAssignmentStatus.ACCEPTED
            ? 'driver_assigned'
            : next;
      await manager.getRepository(DeliveryAssignment).save(assignment);
      await manager.getRepository(DeliveryTracking).save(tracking);
      await manager.getRepository(DeliveryTrackingEvent).save(
        manager.getRepository(DeliveryTrackingEvent).create({
          trackingId: tracking.id,
          status: tracking.status,
          remainingMinutes: tracking.remainingMinutes,
          source: isAdmin ? 'staff' : 'driver',
        }),
      );

      if (
        [
          DeliveryAssignmentStatus.PICKED_UP,
          DeliveryAssignmentStatus.EN_ROUTE,
        ].includes(next) &&
        order.status === 'driver_assigned'
      )
        await this.updateOrderStatus(
          manager,
          order,
          'out_for_delivery',
          actorUserId,
        );
      if (
        next === DeliveryAssignmentStatus.DELIVERED &&
        order.status === 'out_for_delivery'
      )
        await this.updateOrderStatus(manager, order, 'delivered', actorUserId);
      await this.outbox.enqueue(manager, {
        aggregateType: 'delivery',
        aggregateId: assignment.id,
        eventType: 'delivery.status_changed',
        payload: { orderId, assignmentId: assignment.id, status: next },
      });
      return assignment;
    });
  }

  async updateLocation(
    orderId: string,
    dto: UpdateLocationDto,
    actorUserId: string,
    isAdmin = false,
  ) {
    return this.dataSource.transaction(async (manager) => {
      if (!isAdmin) {
        requireEntity(
          await manager.getRepository(DeliveryAssignment).findOne({
            where: { orderId, driverUserId: actorUserId },
          }),
          'Delivery assignment not found',
        );
      }
      const trackingRepo = manager.getRepository(DeliveryTracking);
      const eventRepo = manager.getRepository(DeliveryTrackingEvent);
      const tracking = await trackingRepo.findOne({ where: { orderId } });
      if (!tracking) throw new Error('Delivery tracking not found');

      tracking.currentLatitude = dto.latitude;
      tracking.currentLongitude = dto.longitude;
      tracking.headingDegrees =
        dto.headingDegrees === undefined
          ? undefined
          : String(dto.headingDegrees);
      tracking.speedKph =
        dto.speedKph === undefined ? undefined : String(dto.speedKph);
      tracking.remainingMinutes = dto.remainingMinutes;
      tracking.estimatedArrivalAt = dto.estimatedArrivalAt
        ? new Date(dto.estimatedArrivalAt)
        : tracking.estimatedArrivalAt;
      tracking.lastPingedAt = new Date();
      const saved = await trackingRepo.save(tracking);

      await eventRepo.save(
        eventRepo.create({
          trackingId: saved.id,
          status: saved.status,
          latitude: dto.latitude,
          longitude: dto.longitude,
          remainingMinutes: dto.remainingMinutes,
          source: 'driver',
        }),
      );

      return saved;
    });
  }

  private async updateOrderStatus(
    manager: import('typeorm').EntityManager,
    order: Order,
    next: string,
    actorUserId: string,
  ) {
    const previous = String(order.status);
    order.status = next;
    order.version = String(Number(order.version) + 1);
    if (next === 'delivered') order.deliveredAt = new Date();
    await manager.getRepository(Order).save(order);
    await manager.getRepository(OrderStatusHistory).save(
      manager.getRepository(OrderStatusHistory).create({
        orderId: order.id,
        previousStatus: previous,
        newStatus: next,
        changedByUserId: actorUserId,
        note: 'Delivery lifecycle transition',
      }),
    );
    await this.outbox.enqueue(manager, {
      aggregateType: 'order',
      aggregateId: order.id,
      eventType: 'order.status_changed',
      payload: { orderId: order.id, status: next },
    });
  }
}
