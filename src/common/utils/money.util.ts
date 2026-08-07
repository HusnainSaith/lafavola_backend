export function eurosToMinorUnits(value: number): number {
  return Math.round(value * 100);
}

export function minorUnitsToEuros(value: number): number {
  return value / 100;
}
