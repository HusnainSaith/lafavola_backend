import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BaseRepository } from '../../../common/repositories/base.repository';
import { Cart } from '../entities/cart.entity';

@Injectable()
export class CartRepository extends BaseRepository<Cart> {
  constructor(dataSource: DataSource) {
    super(dataSource, Cart);
  }
}
