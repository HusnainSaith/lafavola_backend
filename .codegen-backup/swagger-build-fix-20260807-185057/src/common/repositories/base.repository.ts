import {
  DataSource,
  DeepPartial,
  EntityTarget,
  FindManyOptions,
  FindOneOptions,
  FindOptionsWhere,
  ObjectLiteral,
  Repository,
} from 'typeorm';

export abstract class BaseRepository<T extends ObjectLiteral> {
  protected readonly repository: Repository<T>;

  protected constructor(dataSource: DataSource, entity: EntityTarget<T>) {
    this.repository = dataSource.getRepository(entity);
  }

  create(input: DeepPartial<T>): T {
    return this.repository.create(input);
  }

  save(entity: DeepPartial<T>): Promise<T> {
    return this.repository.save(entity);
  }

  findOne(options: FindOneOptions<T>): Promise<T | null> {
    return this.repository.findOne(options);
  }

  findById(id: string): Promise<T | null> {
    return this.repository.findOne({
      where: { id } as FindOptionsWhere<T>,
    });
  }

  findMany(options?: FindManyOptions<T>): Promise<T[]> {
    return this.repository.find(options);
  }

  count(where?: FindOptionsWhere<T>): Promise<number> {
    return this.repository.count({ where });
  }

  async deleteById(id: string): Promise<boolean> {
    const result = await this.repository.delete(id);
    return (result.affected ?? 0) > 0;
  }
}
