import {
  BadRequestException,
  ConflictException,
  Injectable,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { DataSource, In } from 'typeorm';
import { AdminListQueryDto } from '../../common/dto/admin-list-query.dto';
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
import { StaffMember } from '../staff/entities/staff-member.entity';
import { User } from '../users/entities/user.entity';
import { Role } from '../roles/entities/role.entity';
import { RoleEnum } from '../roles/role.enum';
import { CreateDriverDto } from './dto/create-driver.dto';
import { UpdateDriverDto } from './dto/update-driver.dto';

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

  async listAdmin(actorUserId: string, query: AdminListQueryDto) {
    const staff = requireEntity(
      await this.dataSource.getRepository(StaffMember).findOne({
        where: { userId: actorUserId, isActive: true },
      }),
      'Staff member not found',
    );
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? 20;
    const builder = this.dataSource
      .getRepository(DeliveryAssignment)
      .createQueryBuilder('assignment')
      .innerJoinAndSelect('assignment.order', 'order')
      .leftJoinAndSelect('assignment.driverUser', 'driver')
      .where('order.restaurant_id = :restaurantId', {
        restaurantId: staff.restaurantId,
      })
      .orderBy('assignment.updatedAt', 'DESC')
      .skip((page - 1) * pageSize)
      .take(pageSize);
    if (query.status)
      builder.andWhere('assignment.status = :status', {
        status: query.status,
      });
    const [data, total] = await builder.getManyAndCount();
    return {
      data,
      meta: { page, pageSize, total, totalPages: Math.ceil(total / pageSize) },
    };
  }

  async dispatchBoard(actorUserId: string) {
    const staff = await this.activeStaff(actorUserId);
    return this.dataSource
      .getRepository(Order)
      .createQueryBuilder('order')
      .leftJoinAndMapOne(
        'order.assignment',
        DeliveryAssignment,
        'assignment',
        'assignment.order_id = order.id',
      )
      .leftJoinAndMapOne(
        'assignment.driverUser',
        User,
        'driver',
        'driver.id = assignment.driver_user_id',
      )
      .where('order.restaurant_id = :restaurantId', {
        restaurantId: staff.restaurantId,
      })
      .andWhere('order.order_type = :orderType', { orderType: 'delivery' })
      .andWhere('order.status IN (:...statuses)', {
        statuses: ['ready', 'driver_assigned', 'out_for_delivery'],
      })
      .orderBy('order.created_at', 'ASC')
      .getMany();
  }

  async listDrivers(actorUserId: string) {
    const actor = await this.activeStaff(actorUserId);
    const drivers = await this.dataSource
      .getRepository(StaffMember)
      .createQueryBuilder('staff')
      .innerJoinAndSelect('staff.user', 'user')
      .innerJoinAndSelect('user.role', 'role')
      .where('staff.restaurant_id = :restaurantId', {
        restaurantId: actor.restaurantId,
      })
      .andWhere('LOWER(staff.job_title) = :jobTitle', { jobTitle: 'driver' })
      .andWhere('role.name = :role', { role: RoleEnum.EMPLOYEE })
      .orderBy('staff.is_active', 'DESC')
      .addOrderBy('user.full_name', 'ASC')
      .getMany();
    return drivers.map((staff) => this.driverResponse(staff, staff.user));
  }

  async createDriver(actorUserId: string, dto: CreateDriverDto) {
    const actor = await this.activeStaff(actorUserId);
    return this.dataSource.transaction(async (manager) => {
      const users = manager.getRepository(User);
      const existing = await users
        .createQueryBuilder('user')
        .where('LOWER(user.email) = LOWER(:email)', { email: dto.email })
        .andWhere('user.archived_at IS NULL')
        .getOne();
      if (existing)
        throw new ConflictException('A user with this email already exists');
      if (dto.phone) {
        const phoneExists = await users.findOne({
          where: { phone: dto.phone },
        });
        if (phoneExists)
          throw new ConflictException('A user with this phone already exists');
      }
      const role = requireEntity(
        await manager.getRepository(Role).findOne({
          where: { name: RoleEnum.EMPLOYEE },
        }),
        'Employee role not found',
      );
      const user = await users.save(
        users.create({
          email: dto.email,
          phone: dto.phone,
          fullName: dto.fullName,
          password: await bcrypt.hash(dto.temporaryPassword, 10),
          roleId: role.id,
          status: 'active',
        }),
      );
      const staff = await manager.getRepository(StaffMember).save(
        manager.getRepository(StaffMember).create({
          userId: user.id,
          restaurantId: actor.restaurantId,
          employeeCode: dto.employeeCode,
          jobTitle: 'Driver',
          isActive: true,
        }),
      );
      return this.driverResponse(staff, user);
    });
  }

  async updateDriver(
    actorUserId: string,
    staffId: string,
    dto: UpdateDriverDto,
  ) {
    const actor = await this.activeStaff(actorUserId);
    return this.dataSource.transaction(async (manager) => {
      const staff = requireEntity(
        await manager.getRepository(StaffMember).findOne({
          where: { id: staffId, restaurantId: actor.restaurantId },
          relations: { user: true },
        }),
        'Driver not found',
      );
      if (staff.jobTitle?.toLowerCase() !== 'driver')
        throw new BadRequestException('Driver not found');
      const user = staff.user;
      if (dto.email && dto.email !== user.email) {
        const conflict = await manager
          .getRepository(User)
          .createQueryBuilder('candidate')
          .where('LOWER(candidate.email) = LOWER(:email)', { email: dto.email })
          .andWhere('candidate.id <> :userId', { userId: user.id })
          .andWhere('candidate.archived_at IS NULL')
          .getOne();
        if (conflict) throw new ConflictException('Email already exists');
      }
      if (dto.phone && dto.phone !== user.phone) {
        const conflict = await manager.getRepository(User).findOne({
          where: { phone: dto.phone },
        });
        if (conflict) throw new ConflictException('Phone already exists');
      }
      if (dto.fullName !== undefined) user.fullName = dto.fullName;
      if (dto.email !== undefined) user.email = dto.email;
      if (dto.phone !== undefined) user.phone = dto.phone;
      if (dto.temporaryPassword)
        user.password = await bcrypt.hash(dto.temporaryPassword, 10);
      if (dto.employeeCode !== undefined)
        staff.employeeCode = dto.employeeCode || undefined;
      if (dto.isActive !== undefined) {
        staff.isActive = dto.isActive;
        user.status = dto.isActive ? 'active' : 'disabled';
      }
      await manager.getRepository(User).save(user);
      await manager.getRepository(StaffMember).save(staff);
      return this.driverResponse(staff, user);
    });
  }

  async deactivateDriver(actorUserId: string, staffId: string) {
    const actor = await this.activeStaff(actorUserId);
    return this.dataSource.transaction(async (manager) => {
      const staff = requireEntity(
        await manager.getRepository(StaffMember).findOne({
          where: { id: staffId, restaurantId: actor.restaurantId },
          relations: { user: true },
        }),
        'Driver not found',
      );
      if (staff.jobTitle?.toLowerCase() !== 'driver')
        throw new BadRequestException('Driver not found');
      const activeAssignments = await manager
        .getRepository(DeliveryAssignment)
        .count({
          where: {
            driverUserId: staff.userId,
            status: In([
              'assigned',
              'accepted',
              'picked_up',
              'en_route',
              'arriving',
            ]),
          },
        });
      if (activeAssignments > 0)
        throw new ConflictException(
          'Reassign active deliveries before deactivating this driver',
        );
      staff.isActive = false;
      staff.user.status = 'disabled';
      await manager.getRepository(StaffMember).save(staff);
      await manager.getRepository(User).save(staff.user);
      await manager.query('DELETE FROM refresh_tokens WHERE user_id=$1', [
        staff.userId,
      ]);
      return this.driverResponse(staff, staff.user);
    });
  }

  async getTracking(actorUserId: string, orderId: string, isAdmin = false) {
    if (isAdmin) {
      const staff = await this.activeStaff(actorUserId);
      requireEntity(
        await this.dataSource.getRepository(Order).findOne({
          where: { id: orderId, restaurantId: staff.restaurantId },
        }),
        'Delivery tracking not found',
      );
    } else {
      const assigned = await this.dataSource
        .getRepository(DeliveryAssignment)
        .findOne({ where: { orderId, driverUserId: actorUserId } });
      if (!assigned) {
        requireEntity(
          await this.dataSource.getRepository(Order).findOne({
            where: { id: orderId, customerId: actorUserId },
          }),
          'Delivery tracking not found',
        );
      }
    }
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

      const staff = requireEntity(
        await manager.getRepository(StaffMember).findOne({
          where: { userId: assignedByUserId, isActive: true },
        }),
        'Staff member not found',
      );
      const order = requireEntity(
        await manager.getRepository(Order).findOne({
          where: { id: orderId, restaurantId: staff.restaurantId },
          lock: { mode: 'pessimistic_write' },
        }),
        'Order not found',
      );
      if (!['ready', 'driver_assigned'].includes(String(order.status)))
        throw new BadRequestException('Order is not ready for delivery');

      const driver = requireEntity(
        await manager
          .getRepository(StaffMember)
          .createQueryBuilder('driverStaff')
          .innerJoin('driverStaff.user', 'driverUser')
          .innerJoin('driverUser.role', 'driverRole')
          .where('driverStaff.user_id = :driverUserId', {
            driverUserId: dto.driverUserId,
          })
          .andWhere('driverStaff.restaurant_id = :restaurantId', {
            restaurantId: staff.restaurantId,
          })
          .andWhere('driverStaff.is_active = true')
          .andWhere('driverUser.status = :status', { status: 'active' })
          .andWhere('LOWER(driverStaff.job_title) = :jobTitle', {
            jobTitle: 'driver',
          })
          .andWhere('driverRole.name = :role', { role: RoleEnum.EMPLOYEE })
          .getOne(),
        'Active driver not found',
      );

      let assignment = await assignmentRepo.findOne({ where: { orderId } });
      if (!assignment) {
        assignment = assignmentRepo.create({
          orderId,
          driverUserId: driver.userId,
          assignedByUserId,
          status: 'assigned',
        });
      } else {
        assignment.driverUserId = driver.userId;
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

  async assignmentForDriver(
    driverUserId: string,
    orderId: string,
    isAdmin = false,
  ) {
    if (!isAdmin) {
      return requireEntity(
        await this.dataSource.getRepository(DeliveryAssignment).findOne({
          where: { orderId, driverUserId },
        }),
        'Delivery assignment not found',
      );
    }
    const staff = requireEntity(
      await this.dataSource.getRepository(StaffMember).findOne({
        where: { userId: driverUserId, isActive: true },
      }),
      'Staff member not found',
    );
    return requireEntity(
      await this.dataSource
        .getRepository(DeliveryAssignment)
        .createQueryBuilder('assignment')
        .innerJoin('assignment.order', 'order')
        .where('assignment.order_id = :orderId', { orderId })
        .andWhere('order.restaurant_id = :restaurantId', {
          restaurantId: staff.restaurantId,
        })
        .getOne(),
      'Delivery assignment not found',
    );
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
      if (isAdmin) {
        const staff = requireEntity(
          await manager.getRepository(StaffMember).findOne({
            where: { userId: actorUserId, isActive: true },
          }),
          'Staff member not found',
        );
        if (order.restaurantId !== staff.restaurantId)
          throw new BadRequestException('Delivery assignment not found');
      }
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
      } else {
        const staff = requireEntity(
          await manager.getRepository(StaffMember).findOne({
            where: { userId: actorUserId, isActive: true },
          }),
          'Staff member not found',
        );
        requireEntity(
          await manager
            .getRepository(DeliveryAssignment)
            .createQueryBuilder('assignment')
            .innerJoin('assignment.order', 'order')
            .where('assignment.order_id = :orderId', { orderId })
            .andWhere('order.restaurant_id = :restaurantId', {
              restaurantId: staff.restaurantId,
            })
            .getOne(),
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

  private async activeStaff(actorUserId: string) {
    return requireEntity(
      await this.dataSource.getRepository(StaffMember).findOne({
        where: { userId: actorUserId, isActive: true },
      }),
      'Staff member not found',
    );
  }

  private driverResponse(staff: StaffMember, user: User) {
    return {
      id: staff.id,
      userId: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      employeeCode: staff.employeeCode,
      jobTitle: staff.jobTitle,
      isActive: staff.isActive,
    };
  }
}
