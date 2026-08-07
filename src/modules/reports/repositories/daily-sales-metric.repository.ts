import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { DailySalesMetric } from '../entities/daily-sales-metric.entity';

@Injectable()
export class DailySalesMetricRepository extends BaseRepository<DailySalesMetric> {
  constructor(dataSource: DataSource) {
    super(dataSource, DailySalesMetric);
  }
}
