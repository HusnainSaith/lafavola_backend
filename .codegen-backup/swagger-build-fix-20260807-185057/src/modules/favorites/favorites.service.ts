import { Injectable } from '@nestjs/common';
import { FavoriteRepository } from './repositories/favorite.repository';
import { CreateFavoriteDto } from './dto/create-favorite.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class FavoritesService {
  constructor(private readonly favorites: FavoriteRepository) {}

  list(customerId: string) {
    return this.favorites.findMany({
      where: { customerId },
      order: { createdAt: 'DESC' },
    });
  }

  create(customerId: string, dto: CreateFavoriteDto) {
    return this.favorites.save(
      this.favorites.create({
        ...dto,
        customerId,
        configurationSnapshot: dto.configurationSnapshot ?? {},
      }),
    );
  }

  async remove(customerId: string, id: string): Promise<void> {
    const favorite = requireEntity(
      await this.favorites.findOne({ where: { id, customerId } }),
      'Favorite not found',
    );
    await this.favorites.deleteById(favorite.id);
  }
}
