import { Module } from '@nestjs/common';
import { OptionGroupsController } from './option-groups.controller';
import { OptionGroupsService } from './option-groups.service';
import { OptionGroupRepository } from './repositories/option-group.repository';

@Module({
  controllers: [OptionGroupsController],
  providers: [OptionGroupsService, OptionGroupRepository],
  exports: [OptionGroupsService, OptionGroupRepository],
})
export class OptionGroupsModule {}
