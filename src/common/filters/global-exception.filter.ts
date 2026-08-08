import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { QueryFailedError } from 'typeorm';

interface ErrorResponse {
  success: false;
  message: string;
  error: string;
  statusCode: number;
  timestamp: string;
  path: string;
  details?: string[] | Record<string, unknown>;
  requestId?: string;
}

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const errorResponse = this.buildErrorResponse(exception, request);
    const requestId = request.headers['x-request-id'];
    if (typeof requestId === 'string') errorResponse.requestId = requestId;

    this.logError(exception, request, errorResponse);
    response.status(errorResponse.statusCode).json(errorResponse);
  }

  private buildErrorResponse(
    exception: unknown,
    request: Request,
  ): ErrorResponse {
    const timestamp = new Date().toISOString();
    const path = request.url;

    if (exception instanceof HttpException) {
      return this.handleHttpException(exception, path, timestamp);
    }

    if (exception instanceof QueryFailedError) {
      return this.handleDatabaseError(exception, path, timestamp);
    }

    if (exception instanceof Error) {
      return this.handleGenericError(exception, path, timestamp);
    }

    return this.handleUnknownError(path, timestamp);
  }

  private handleHttpException(
    exception: HttpException,
    path: string,
    timestamp: string,
  ): ErrorResponse {
    const status = exception.getStatus();
    const exceptionResponse = exception.getResponse();

    const baseResponse: ErrorResponse = {
      success: false,
      message: exception.message,
      error: HttpStatus[status] || 'Unknown Error',
      statusCode: status,
      timestamp,
      path,
    };

    if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
      const responseObj = exceptionResponse as Record<string, unknown>;

      if ('message' in responseObj) {
        const messages = responseObj.message;
        if (Array.isArray(messages)) {
          baseResponse.message = 'Validation failed';
          baseResponse.details = messages;
        } else {
          baseResponse.message = String(messages);
        }
      }

      if ('error' in responseObj && typeof responseObj.error === 'string') {
        baseResponse.error = responseObj.error;
      }
    }

    return baseResponse;
  }

  private handleDatabaseError(
    exception: QueryFailedError,
    path: string,
    timestamp: string,
  ): ErrorResponse {
    const code = (
      exception as QueryFailedError & { driverError?: { code?: string } }
    ).driverError?.code;

    if (code === '23505') {
      return {
        success: false,
        message: 'Resource already exists',
        error: 'Conflict',
        statusCode: HttpStatus.CONFLICT,
        timestamp,
        path,
      };
    }

    if (code === '23503') {
      return {
        success: false,
        message: 'The operation conflicts with a referenced resource',
        error: 'Conflict',
        statusCode: HttpStatus.CONFLICT,
        timestamp,
        path,
      };
    }

    if (code === '23502' || code === '23514') {
      return {
        success: false,
        message: 'The data violates a database constraint',
        error: 'Bad Request',
        statusCode: HttpStatus.BAD_REQUEST,
        timestamp,
        path,
      };
    }

    return {
      success: false,
      message: 'Internal server error',
      error: 'Internal Server Error',
      statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
      timestamp,
      path,
    };
  }

  private handleGenericError(
    exception: Error,
    path: string,
    timestamp: string,
  ): ErrorResponse {
    return {
      success: false,
      message: 'Internal server error',
      error: 'Internal Server Error',
      statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
      timestamp,
      path,
    };
  }

  private handleUnknownError(path: string, timestamp: string): ErrorResponse {
    return {
      success: false,
      message: 'Internal server error',
      error: 'Internal Server Error',
      statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
      timestamp,
      path,
    };
  }

  private logError(
    exception: unknown,
    request: Request,
    errorResponse: ErrorResponse,
  ): void {
    const { method, url, headers } = request;
    const userAgent = headers['user-agent'] || 'Unknown';

    const logContext = {
      method,
      url,
      userAgent,
      statusCode: errorResponse.statusCode,
      timestamp: errorResponse.timestamp,
    };

    // Log all errors as warnings with full context for debugging
    this.logger.warn(
      `${method} ${url} - ${errorResponse.statusCode} - ${errorResponse.message}`,
      JSON.stringify(logContext),
    );

    if (errorResponse.statusCode >= HttpStatus.INTERNAL_SERVER_ERROR) {
      const databaseError = exception as QueryFailedError & {
        driverError?: { code?: string; constraint?: string };
      };
      const isDatabaseError = exception instanceof QueryFailedError;
      this.logger.error(
        JSON.stringify({
          exceptionType:
            exception instanceof Error
              ? exception.constructor.name
              : typeof exception,
          // QueryFailedError messages can contain SQL and bound values. Keep
          // those out of logs while retaining useful details for ordinary
          // application errors.
          exceptionMessage:
            exception instanceof Error && !isDatabaseError
              ? exception.message
              : undefined,
          databaseCode: databaseError.driverError?.code,
          databaseConstraint: databaseError.driverError?.constraint,
          requestId: errorResponse.requestId,
          stack:
            exception instanceof Error && !isDatabaseError
              ? exception.stack
              : undefined,
        }),
      );
    }
  }
}
