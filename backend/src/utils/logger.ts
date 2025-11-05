import winston from 'winston';
import path from 'path';

// Define log format
const logFormat = winston.format.combine(
  winston.format.timestamp({
    format: 'YYYY-MM-DD HH:mm:ss'
  }),
  winston.format.errors({ stack: true }),
  winston.format.json()
);

// Console format for development
const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({
    format: 'HH:mm:ss'
  }),
  winston.format.printf(({ timestamp, level, message, stack }) => {
    return `${timestamp} ${level}: ${stack || message}`;
  })
);

// Create logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: logFormat,
  defaultMeta: { service: 'study-planner-api' },
  transports: [
    // Console transport for development
    new winston.transports.Console({
      format: process.env.NODE_ENV === 'development' ? consoleFormat : logFormat
    }),

    // File transport for errors
    new winston.transports.File({
      filename: path.join(process.cwd(), 'logs', 'error.log'),
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 5,
      format: logFormat
    }),

    // File transport for all logs
    new winston.transports.File({
      filename: path.join(process.cwd(), 'logs', 'combined.log'),
      maxsize: 5242880, // 5MB
      maxFiles: 5,
      format: logFormat
    })
  ],

  // Handle uncaught exceptions and rejections
  exceptionHandlers: [
    new winston.transports.File({
      filename: path.join(process.cwd(), 'logs', 'exceptions.log')
    })
  ],

  rejectionHandlers: [
    new winston.transports.File({
      filename: path.join(process.cwd(), 'logs', 'rejections.log')
    })
  ]
});

// Add request logging helper
export const logRequest = (req: any, res: any, responseTime?: number) => {
  const { method, url, ip, headers } = req;
  const { statusCode } = res;
  const userAgent = headers['user-agent'] || 'Unknown';

  logger.info('HTTP Request', {
    method,
    url,
    statusCode,
    ip,
    userAgent,
    responseTime: responseTime ? `${responseTime}ms` : undefined,
    timestamp: new Date().toISOString()
  });
};

// Add error logging helper
export const logError = (error: Error, context?: any) => {
  logger.error('Application Error', {
    message: error.message,
    stack: error.stack,
    context,
    timestamp: new Date().toISOString()
  });
};

// Add performance logging helper
export const logPerformance = (operation: string, duration: number, metadata?: any) => {
  logger.info('Performance Metric', {
    operation,
    duration: `${duration}ms`,
    metadata,
    timestamp: new Date().toISOString()
  });
};

// Add database query logging helper
export const logQuery = (query: string, duration: number, params?: any) => {
  logger.debug('Database Query', {
    query: query.substring(0, 200) + (query.length > 200 ? '...' : ''),
    duration: `${duration}ms`,
    params: params ? JSON.stringify(params).substring(0, 100) : undefined,
    timestamp: new Date().toISOString()
  });
};

// Add authentication logging helper
export const logAuth = (action: string, userId?: string, success: boolean, ip?: string) => {
  logger.info('Authentication Event', {
    action,
    userId,
    success,
    ip,
    timestamp: new Date().toISOString()
  });
};

// Add API response logging helper
export const logApiResponse = (req: any, responseTime: number, responseSize?: number) => {
  const { method, url } = req;

  logger.info('API Response', {
    method,
    url,
    responseTime: `${responseTime}ms`,
    responseSize: responseSize ? `${responseSize} bytes` : undefined,
    timestamp: new Date().toISOString()
  });
};

export default logger;