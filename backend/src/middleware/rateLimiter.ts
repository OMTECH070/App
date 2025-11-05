import { RateLimiterMemory, RateLimiterRedis } from 'rate-limiter-flexible';
import { Request, Response, NextFunction } from 'express';
import { getRedisClient } from '@/config/redis';
import ResponseService from '@/utils/response';
import { logAuth } from '@/utils/logger';

// Rate limiter options
const RATE_LIMIT_WINDOW_MS = parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000'); // 15 minutes
const RATE_LIMIT_MAX_REQUESTS = parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100');

// Create rate limiters
let rateLimiter: RateLimiterMemory | RateLimiterRedis;

// Try to use Redis for distributed rate limiting, fallback to memory
try {
  const redisClient = getRedisClient();
  rateLimiter = new RateLimiterRedis({
    storeClient: redisClient,
    keyPrefix: 'rl_flx:',
    points: RATE_LIMIT_MAX_REQUESTS,
    duration: RATE_LIMIT_WINDOW_MS / 1000, // Convert to seconds
    blockDuration: 60, // Block for 1 minute if limit exceeded
    execEvenly: true, // Distribute requests evenly
  });
} catch (error) {
  // Fallback to memory-based rate limiting
  rateLimiter = new RateLimiterMemory({
    keyPrefix: 'rl_mem:',
    points: RATE_LIMIT_MAX_REQUESTS,
    duration: RATE_LIMIT_WINDOW_MS / 1000,
    blockDuration: 60,
    execEvenly: true,
  });
}

// Specialized rate limiters for different endpoints
export const authRateLimiter = new RateLimiterMemory({
  keyPrefix: 'rl_auth:',
  points: 5, // 5 requests
  duration: 900, // per 15 minutes
  blockDuration: 900,
});

export const uploadRateLimiter = new RateLimiterMemory({
  keyPrefix: 'rl_upload:',
  points: 3, // 3 requests
  duration: 3600, // per hour
  blockDuration: 3600,
});

export const aiRateLimiter = new RateLimiterMemory({
  keyPrefix: 'rl_ai:',
  points: 10, // 10 requests
  duration: 3600, // per hour
  blockDuration: 3600,
});

// Main rate limiting middleware
export const rateLimiterMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Get client IP
    const ip = req.ip || req.connection.remoteAddress || req.headers['x-forwarded-for'];
    const key = `${ip}:${req.path}`;

    // Consume a point
    const result = await rateLimiter.consume(key);

    // Add rate limit headers
    res.set({
      'X-RateLimit-Limit': RATE_LIMIT_MAX_REQUESTS.toString(),
      'X-RateLimit-Remaining': Math.max(0, result.remainingPoints).toString(),
      'X-RateLimit-Reset': new Date(Date.now() + result.msBeforeNext).toISOString(),
    });

    next();
  } catch (rejRes: any) {
    // Rate limit exceeded
    const secs = Math.round(rejRes.msBeforeNext / 1000) || 1;

    // Log rate limit violation
    logAuth('RATE_LIMIT_EXCEEDED', undefined, false, req.ip);

    res.set({
      'X-RateLimit-Limit': RATE_LIMIT_MAX_REQUESTS.toString(),
      'X-RateLimit-Remaining': '0',
      'X-RateLimit-Reset': new Date(Date.now() + rejRes.msBeforeNext).toISOString(),
      'Retry-After': secs.toString(),
    });

    ResponseService.rateLimitExceeded(res, secs);
  }
};

// Authentication rate limiter
export const authRateLimiterMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const ip = req.ip || req.connection.remoteAddress || req.headers['x-forwarded-for'];
    const key = `auth:${ip}`;

    await authRateLimiter.consume(key);
    next();
  } catch (rejRes: any) {
    const secs = Math.round(rejRes.msBeforeNext / 1000) || 1;
    res.set('Retry-After', secs.toString());
    ResponseService.rateLimitExceeded(res, secs);
  }
};

// Upload rate limiter
export const uploadRateLimiterMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const ip = req.ip || req.connection.remoteAddress || req.headers['x-forwarded-for'];
    const key = `upload:${ip}`;

    await uploadRateLimiter.consume(key);
    next();
  } catch (rejRes: any) {
    const secs = Math.round(rejRes.msBeforeNext / 1000) || 1;
    res.set('Retry-After', secs.toString());
    ResponseService.rateLimitExceeded(res, secs);
  }
};

// AI rate limiter
export const aiRateLimiterMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Try to get user ID from authenticated request
    const userId = (req as any).user?.id;
    const ip = req.ip || req.connection.remoteAddress || req.headers['x-forwarded-for'];
    const key = `ai:${userId || ip}`;

    await aiRateLimiter.consume(key);
    next();
  } catch (rejRes: any) {
    const secs = Math.round(rejRes.msBeforeNext / 1000) || 1;
    res.set('Retry-After', secs.toString());
    ResponseService.rateLimitExceeded(res, secs);
  }
};

// Create custom rate limiter
export const createCustomRateLimiter = (
  options: {
    points?: number;
    duration?: number;
    blockDuration?: number;
    keyPrefix?: string;
  } = {}
) => {
  const {
    points = 10,
    duration = 3600,
    blockDuration = 3600,
    keyPrefix = 'rl_custom:'
  } = options;

  return new RateLimiterMemory({
    keyPrefix,
    points,
    duration,
    blockDuration,
  });
};

// Custom rate limiter middleware
export const createCustomRateLimiterMiddleware = (
  rateLimiter: RateLimiterMemory,
  getKey: (req: Request) => string = (req) => req.ip || 'unknown'
) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      const key = getKey(req);
      await rateLimiter.consume(key);
      next();
    } catch (rejRes: any) {
      const secs = Math.round(rejRes.msBeforeNext / 1000) || 1;
      res.set('Retry-After', secs.toString());
      ResponseService.rateLimitExceeded(res, secs);
    }
  };
};

export default rateLimiterMiddleware;