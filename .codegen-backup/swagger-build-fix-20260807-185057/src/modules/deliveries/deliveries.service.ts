import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { DeliveryTrackingRepository } from './repositories/delivery-tracking.repository';
import { DeliveryAssignment } from './entities/delivery-assignment.entity';
import { DeliveryTracking } from './entities/delivery-tracking.entity';
import { DeliveryTrackingEvent } from './entities/delivery-tracking-event.entity';
import { AssignDriverDto } from './dto/assign-driver.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class DeliveriesService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly tracking: DeliveryTrackingRepository,
  ) {}

  async getTracking(orderId: string) {
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
      return assignment;
    });
  }

  async updateLocation(orderId: string, dto: UpdateLocationDto) {
    return this.dataSource.transaction(async (manager) => {
      const trackingRepo = manager.getRepository(DeliveryTracking);
      const eventRepo = manager.getRepository(DeliveryTrackingEvent);
      const tracking = await trackingRepo.findOne({ where: { orderId } });
      if (!tracking) throw new Error('Delivery tracking not found');

      tracking.currentLatitude = dto.latitude;
      tracking.currentLongitude = dto.longitude;
      tracking.headingDegrees = dto.headingDegrees;
      tracking.speedKph = dto.speedKph;
      tracking.remainingMinutes = dto.remainingMinutes;
      tracking.estimatedArrivalAt = dto.estimatedArrivalAt
        ? new Date(dto.estimatedArrivalAt)
        : tracking.estimatedArrivalAt;
      tracking.lastPingedAt = new Date();
      if (dto.status) tracking.status = dto.status as any;
      const saved = await trackingRepo.save(tracking);

      await eventRepo.save(
        eventRepo.create({
          trackingId: saved.id,
          status: dto.status,
          latitude: dto.latitude,
          longitude: dto.longitude,
          remainingMinutes: dto.remainingMinutes,
          source: 'driver',
        }),
      );

      return saved;
    });
  }
}
