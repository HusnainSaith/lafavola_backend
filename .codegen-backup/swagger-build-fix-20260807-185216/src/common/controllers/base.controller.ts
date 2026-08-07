import { UseFilters } from '@nestjs/common';
import { GlobalExceptionFilter } from '../filters/global-exception.filter';

import { ApiBearerAuth, ApiBody, ApiOperation, ApiParam, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';

@UseFilters(GlobalExceptionFilter)
export abstract class BaseController {
  protected handleAsyncOperation<T>(operation: Promise<T>): Promise<T> {
    return operation.catch((error: Error) => {
      throw error;
    });
  }
}
