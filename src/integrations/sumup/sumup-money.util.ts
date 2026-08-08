import { BadRequestException } from '@nestjs/common';

export function minorToMajorString(amountMinor: number): string {
  if (!Number.isSafeInteger(amountMinor) || amountMinor < 0) {
    throw new BadRequestException('Payment amount is invalid');
  }
  return `${Math.floor(amountMinor / 100)}.${String(amountMinor % 100).padStart(2, '0')}`;
}

export function majorToMinor(value: unknown): number {
  const normalized = String(value);
  if (!/^\d+(\.\d{1,2})?$/.test(normalized)) {
    throw new Error('Provider amount is invalid');
  }
  const [whole, fraction = ''] = normalized.split('.');
  const result = Number(whole) * 100 + Number(fraction.padEnd(2, '0'));
  if (!Number.isSafeInteger(result))
    throw new Error('Provider amount is invalid');
  return result;
}
