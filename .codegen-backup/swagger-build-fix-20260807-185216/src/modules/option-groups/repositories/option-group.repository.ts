import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { OptionGroup } from '../entities/option-group.entity';

@Injectable()
export class OptionGroupRepository extends BaseRepository<OptionGroup> {
  constructor(dataSource: DataSource) {
    super(dataSource, OptionGroup);
  }
}
