export enum OutboxStatus {
  PENDING = 'pending',
  PROCESSING = 'processing',
  PUBLISHED = 'published',
  FAILED = 'failed',
  DEAD_LETTER = 'dead_letter',
}
