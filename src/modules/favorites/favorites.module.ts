import { Module } from '@nestjs/common';
import { CartsModule } from '../carts/carts.module';
import { FavoritesController } from './favorites.controller';
import { FavoritesService } from './favorites.service';
import { FavoriteRepository } from './repositories/favorite.repository';

@Module({
  imports: [CartsModule],
  controllers: [FavoritesController],
  providers: [FavoritesService, FavoriteRepository],
  exports: [FavoritesService],
})
export class FavoritesModule {}
