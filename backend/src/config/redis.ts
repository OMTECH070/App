import { createClient, RedisClientType } from 'redis';
import { logger } from '@/utils/logger';

let client: RedisClientType;

export async function connectRedis(): Promise<RedisClientType> {
  try {
    client = createClient({
      url: process.env.REDIS_URL || 'redis://localhost:6379',
      socket: {
        connectTimeout: parseInt(process.env.REDIS_CONNECT_TIMEOUT || '5000'),
        lazyConnect: true
      },
      password: process.env.REDIS_PASSWORD
    });

    client.on('error', (error) => {
      logger.error('❌ Redis Client Error:', error);
    });

    client.on('connect', () => {
      logger.info('✅ Redis connected successfully');
    });

    client.on('ready', () => {
      logger.info('🔥 Redis ready for commands');
    });

    client.on('end', () => {
      logger.info('📴 Redis connection closed');
    });

    await client.connect();

    // Test connection
    await client.ping();

    logger.info('🔴 Redis connection established');

    return client;
  } catch (error) {
    logger.error('❌ Redis connection failed:', error);
    // Don't throw error here, allow app to run without Redis
    logger.warn('⚠️  Application will continue without Redis caching');
    return null as any;
  }
}

export function getRedisClient(): RedisClientType {
  if (!client) {
    throw new Error('Redis not initialized. Call connectRedis() first.');
  }
  return client;
}

export async function closeRedis(): Promise<void> {
  if (client && client.isOpen) {
    await client.quit();
    logger.info('🔴 Redis connection closed');
  }
}

// Cache helper functions
export class CacheService {
  private static instance: CacheService;
  private client: RedisClientType;

  constructor(redisClient: RedisClientType) {
    this.client = redisClient;
  }

  static getInstance(redisClient?: RedisClientType): CacheService {
    if (!CacheService.instance) {
      if (!redisClient) {
        throw new Error('Redis client required for first instantiation');
      }
      CacheService.instance = new CacheService(redisClient);
    }
    return CacheService.instance;
  }

  async get(key: string): Promise<string | null> {
    try {
      return await this.client.get(key);
    } catch (error) {
      logger.error(`❌ Cache GET error for key ${key}:`, error);
      return null;
    }
  }

  async set(key: string, value: string, ttl?: number): Promise<boolean> {
    try {
      if (ttl) {
        await this.client.setEx(key, ttl, value);
      } else {
        await this.client.set(key, value);
      }
      return true;
    } catch (error) {
      logger.error(`❌ Cache SET error for key ${key}:`, error);
      return false;
    }
  }

  async del(key: string): Promise<boolean> {
    try {
      const result = await this.client.del(key);
      return result > 0;
    } catch (error) {
      logger.error(`❌ Cache DEL error for key ${key}:`, error);
      return false;
    }
  }

  async exists(key: string): Promise<boolean> {
    try {
      const result = await this.client.exists(key);
      return result === 1;
    } catch (error) {
      logger.error(`❌ Cache EXISTS error for key ${key}:`, error);
      return false;
    }
  }

  async increment(key: string, amount = 1): Promise<number> {
    try {
      return await this.client.incrBy(key, amount);
    } catch (error) {
      logger.error(`❌ Cache INCR error for key ${key}:`, error);
      return 0;
    }
  }

  async expire(key: string, ttl: number): Promise<boolean> {
    try {
      const result = await this.client.expire(key, ttl);
      return result === 1;
    } catch (error) {
      logger.error(`❌ Cache EXPIRE error for key ${key}:`, error);
      return false;
    }
  }

  // Cache user session
  async cacheUserSession(userId: string, sessionData: any, ttl = 3600): Promise<boolean> {
    const key = `session:${userId}`;
    return await this.set(key, JSON.stringify(sessionData), ttl);
  }

  // Get cached user session
  async getUserSession(userId: string): Promise<any | null> {
    const key = `session:${userId}`;
    const cached = await this.get(key);
    return cached ? JSON.parse(cached) : null;
  }

  // Cache AI insights
  async cacheAIInsight(userId: string, insight: any, ttl = 86400): Promise<boolean> {
    const key = `ai_insight:${userId}`;
    return await this.set(key, JSON.stringify(insight), ttl);
  }

  // Get cached AI insight
  async getAIInsight(userId: string): Promise<any | null> {
    const key = `ai_insight:${userId}`;
    const cached = await this.get(key);
    return cached ? JSON.parse(cached) : null;
  }

  // Cache study analytics
  async cacheAnalytics(userId: string, analytics: any, ttl = 1800): Promise<boolean> {
    const key = `analytics:${userId}`;
    return await this.set(key, JSON.stringify(analytics), ttl);
  }

  // Get cached analytics
  async getAnalytics(userId: string): Promise<any | null> {
    const key = `analytics:${userId}`;
    const cached = await this.get(key);
    return cached ? JSON.parse(cached) : null;
  }
}