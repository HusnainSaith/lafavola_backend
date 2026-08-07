import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { ItemSalesMetric } from '../entities/item-sales-metric.entity';

@Injectable()
export class ItemSalesMetricRepository extends BaseRepository<ItemSalesMetric> {
  constructor(dataSource: DataSource) {
    super(dataSource, ItemSalesMetric);
  }
}
