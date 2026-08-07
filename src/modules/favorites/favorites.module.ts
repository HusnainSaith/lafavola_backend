import { Module } from '@nestjs/common';
import { FavoritesController } from './favorites.controller';
import { FavoritesService } from './favorites.service';
import { FavoriteRepository } from './repositories/favorite.repository';

@Module({
  controllers: [FavoritesController],
  providers: [FavoritesService, FavoriteRepository],
  exports: [FavoritesService],
})
export class FavoritesModule {}
