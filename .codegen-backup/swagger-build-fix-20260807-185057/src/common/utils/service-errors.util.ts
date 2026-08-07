import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';

export function requireEntity<T>(
  entity: T | null | undefined,
  message: string,
): T {
  if (!entity) {
    throw new NotFoundException(message);
  }
  return entity;
}

export function assertCondition(
  condition: unknown,
  message: string,
): asserts condition {
  if (!condition) {
    throw new BadRequestException(message);
  }
}

export function assertUnique(
  condition: unknown,
  message: string,
): asserts condition {
  if (!condition) {
    throw new ConflictException(message);
  }
}
