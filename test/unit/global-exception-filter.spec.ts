import {
  ArgumentsHost,
  BadRequestException,
  ForbiddenException,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { QueryFailedError } from 'typeorm';
import { GlobalExceptionFilter } from '../../src/common/filters/global-exception.filter';

function invoke(exception: unknown) {
  const status = jest.fn().mockReturnThis();
  const json = jest.fn();
  const host = {
    switchToHttp: () => ({
      getResponse: () => ({ status, json }),
      getRequest: () => ({
        method: 'POST',
        url: '/resource',
        headers: { 'x-request-id': 'request-1' },
      }),
    }),
  } as unknown as ArgumentsHost;
  new GlobalExceptionFilter().catch(exception, host);
  return { status, body: json.mock.calls[0][0] };
}

describe('GlobalExceptionFilter', () => {
  it('maps PostgreSQL unique violations to 409', () => {
    const error = new QueryFailedError('INSERT', [], {
      code: '23505',
    } as never);
    const result = invoke(error);
    expect(result.status).toHaveBeenCalledWith(409);
    expect(result.body).not.toHaveProperty('sql');
  });

  it.each([
    [new UnauthorizedException(), 401],
    [new ForbiddenException(), 403],
    [new NotFoundException(), 404],
  ])('preserves expected HTTP exception status', (error, status) => {
    expect(invoke(error).status).toHaveBeenCalledWith(status);
  });

  it('returns class-validator details as a safe 400 contract', () => {
    const result = invoke(new BadRequestException(['email: must be an email']));
    expect(result.status).toHaveBeenCalledWith(400);
    expect(result.body.details).toEqual(['email: must be an email']);
  });

  it.each([
    ['23503', 409],
    ['23502', 400],
    ['23514', 400],
  ])('maps PostgreSQL %s safely', (code, status) => {
    const result = invoke(
      new QueryFailedError('SQL containing secret-token', [], {
        code,
      } as never),
    );
    expect(result.status).toHaveBeenCalledWith(status);
    expect(JSON.stringify(result.body)).not.toContain('secret-token');
  });

  it('sanitizes unexpected database failures as 500', () => {
    const error = new QueryFailedError('SELECT secret', [], {
      code: '42703',
    } as never);
    const result = invoke(error);
    expect(result.status).toHaveBeenCalledWith(500);
    expect(result.body.message).toBe('Internal server error');
    expect(JSON.stringify(result.body)).not.toContain('SELECT secret');
    expect(result.body.requestId).toBe('request-1');
  });
});
