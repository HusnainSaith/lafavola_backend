import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { PizzaBuilderRule } from '../entities/pizza-builder-rule.entity';

@Injectable()
export class PizzaBuilderRuleRepository extends BaseRepository<PizzaBuilderRule> {
  constructor(dataSource: DataSource) {
    super(dataSource, PizzaBuilderRule);
  }
}
