import { Response } from 'express';
import { ApiResponse, ApiError, PaginationMeta } from '@/types';

export class ResponseService {
  /**
   * Send a success response
   */
  static success<T>(
    res: Response,
    data?: T,
    message?: string,
    statusCode: number = 200,
    meta?: Omit<ApiResponse<T>['meta'], 'timestamp'>
  ): Response {
    const response: ApiResponse<T> = {
      success: true,
      data,
      meta: {
        timestamp: new Date().toISOString(),
        ...meta
      }
    };

    if (message) {
      (response as any).message = message;
    }

    return res.status(statusCode).json(response);
  }

  /**
   * Send an error response
   */
  static error(
    res: Response,
    error: ApiError | string,
    statusCode: number = 500,
    details?: any
  ): Response {
    let apiError: ApiError;

    if (typeof error === 'string') {
      apiError = {
        code: this.getDefaultErrorCode(statusCode),
        message: error,
        details
      };
    } else {
      apiError = {
        ...error,
        details: details || error.details
      };
    }

    const response: ApiResponse = {
      success: false,
      error: apiError,
      meta: {
        timestamp: new Date().toISOString()
      }
    };

    return res.status(statusCode).json(response);
  }

  /**
   * Send a paginated response
   */
  static paginated<T>(
    res: Response,
    data: T[],
    pagination: PaginationMeta,
    message?: string
  ): Response {
    return this.success(
      res,
      data,
      message,
      200,
      { pagination }
    );
  }

  /**
   * Send a created response
   */
  static created<T>(
    res: Response,
    data: T,
    message: string = 'Resource created successfully'
  ): Response {
    return this.success(res, data, message, 201);
  }

  /**
   * Send a no content response
   */
  static noContent(res: Response): Response {
    return res.status(204).send();
  }

  /**
   * Send a bad request response
   */
  static badRequest(
    res: Response,
    error: ApiError | string,
    details?: any
  ): Response {
    return this.error(res, error, 400, details);
  }

  /**
   * Send an unauthorized response
   */
  static unauthorized(
    res: Response,
    error: ApiError | string = 'Authentication required'
  ): Response {
    return this.error(res, error, 401);
  }

  /**
   * Send a forbidden response
   */
  static forbidden(
    res: Response,
    error: ApiError | string = 'Access forbidden'
  ): Response {
    return this.error(res, error, 403);
  }

  /**
   * Send a not found response
   */
  static notFound(
    res: Response,
    error: ApiError | string = 'Resource not found'
  ): Response {
    return this.error(res, error, 404);
  }

  /**
   * Send a conflict response
   */
  static conflict(
    res: Response,
    error: ApiError | string,
    details?: any
  ): Response {
    return this.error(res, error, 409, details);
  }

  /**
   * Send a validation error response
   */
  static validationError(
    res: Response,
    details: any
  ): Response {
    return this.error(
      res,
      {
        code: 'VALIDATION_ERROR',
        message: 'Validation failed',
        details
      },
      422
    );
  }

  /**
   * Send a rate limit exceeded response
   */
  static rateLimitExceeded(
    res: Response,
    retryAfter?: number
  ): Response {
    const response = this.error(
      res,
      {
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Too many requests, please try again later',
        details: retryAfter ? { retryAfter } : undefined
      },
      429
    );

    if (retryAfter) {
      res.set('Retry-After', retryAfter.toString());
    }

    return response;
  }

  /**
   * Send an internal server error response
   */
  static internalError(
    res: Response,
    error: ApiError | string = 'Internal server error',
    details?: any
  ): Response {
    // Don't expose internal error details in production
    const message = process.env.NODE_ENV === 'production'
      ? 'Internal server error'
      : error;

    return this.error(res, message, 500, details);
  }

  /**
   * Get default error code based on status code
   */
  private static getDefaultErrorCode(statusCode: number): string {
    const errorCodes: Record<number, string> = {
      400: 'BAD_REQUEST',
      401: 'UNAUTHORIZED',
      403: 'FORBIDDEN',
      404: 'NOT_FOUND',
      409: 'CONFLICT',
      422: 'VALIDATION_ERROR',
      429: 'RATE_LIMIT_EXCEEDED',
      500: 'INTERNAL_ERROR',
      502: 'BAD_GATEWAY',
      503: 'SERVICE_UNAVAILABLE',
      504: 'GATEWAY_TIMEOUT'
    };

    return errorCodes[statusCode] || 'UNKNOWN_ERROR';
  }

  /**
   * Handle async route errors
   */
  static asyncHandler(
    fn: (req: any, res: Response, next: any) => Promise<any>
  ) {
    return (req: any, res: Response, next: any) => {
      Promise.resolve(fn(req, res, next)).catch(next);
    };
  }
}

export default ResponseService;