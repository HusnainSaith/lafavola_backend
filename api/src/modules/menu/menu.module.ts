import { Module } from '@nestjs/common';
import { MenuController } from './menu.controller';
import { MenuService } from './menu.service';
import { MenuItemRepository } from './repositories/menu-item.repository';

@Module({
  controllers: [MenuController],
  providers: [MenuService, MenuItemRepository],
  exports: [MenuService, MenuItemRepository],
})
export class MenuModule {}
