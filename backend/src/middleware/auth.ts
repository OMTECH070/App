import { Request, Response, NextFunction } from 'express';
import { verifyFirebaseToken } from '@/config/firebase';
import { getDatabasePool } from '@/config/database';
import { User } from '@/types';
import ResponseService from '@/utils/response';
import { logAuth } from '@/utils/logger';

// Extend Request type to include user
declare global {
  namespace Express {
    interface Request {
      user?: User;
    }
  }
}

export const authenticateToken = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      logAuth('AUTHENTICATION_FAILED', undefined, false, req.ip);
      ResponseService.unauthorized(res, 'Authentication token required');
      return;
    }

    // Verify Firebase token
    const decodedToken = await verifyFirebaseToken(token);
    const uid = decodedToken.uid;

    // Get user from database
    const pool = getDatabasePool();
    const result = await pool.query(
      `SELECT
        id, email, display_name, profile_photo_url,
        study_goal_hours, timezone, is_premium,
        preferences, created_at, updated_at
       FROM users
       WHERE id = $1 AND is_active = true`,
      [uid]
    );

    if (result.rows.length === 0) {
      logAuth('USER_NOT_FOUND', uid, false, req.ip);
      ResponseService.unauthorized(res, 'User not found');
      return;
    }

    const user: User = {
      id: result.rows[0].id,
      email: result.rows[0].email,
      displayName: result.rows[0].display_name,
      profilePhotoUrl: result.rows[0].profile_photo_url,
      studyGoalHours: result.rows[0].study_goal_hours,
      timezone: result.rows[0].timezone,
      isPremium: result.rows[0].is_premium,
      preferences: result.rows[0].preferences || {
        notifications: {
          studyReminders: true,
          breakReminders: true,
          achievementNotifications: true,
          dailyProgressUpdates: true,
          reminderMinutes: [15, 5]
        },
        studyTimes: {
          preferredStudyHours: { start: '09:00', end: '21:00' },
          defaultSessionDuration: 45,
          defaultBreakDuration: 10,
          studyStyle: 'mixed'
        },
        appearance: {
          theme: 'system',
          accentColor: '#007AFF'
        }
      },
      createdAt: result.rows[0].created_at,
      updatedAt: result.rows[0].updated_at
    };

    // Attach user to request object
    req.user = user;

    logAuth('AUTHENTICATION_SUCCESS', user.id, true, req.ip);
    next();
  } catch (error) {
    logAuth('AUTHENTICATION_ERROR', undefined, false, req.ip);
    ResponseService.unauthorized(res, 'Invalid authentication token');
  }
};

// Optional authentication - doesn't fail if no token
export const optionalAuth = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1];

    if (token) {
      const decodedToken = await verifyFirebaseToken(token);
      const uid = decodedToken.uid;

      const pool = getDatabasePool();
      const result = await pool.query(
        `SELECT
          id, email, display_name, profile_photo_url,
          study_goal_hours, timezone, is_premium,
          preferences, created_at, updated_at
         FROM users
         WHERE id = $1 AND is_active = true`,
        [uid]
      );

      if (result.rows.length > 0) {
        req.user = {
          id: result.rows[0].id,
          email: result.rows[0].email,
          displayName: result.rows[0].display_name,
          profilePhotoUrl: result.rows[0].profile_photo_url,
          studyGoalHours: result.rows[0].study_goal_hours,
          timezone: result.rows[0].timezone,
          isPremium: result.rows[0].is_premium,
          preferences: result.rows[0].preferences || {},
          createdAt: result.rows[0].created_at,
          updatedAt: result.rows[0].updated_at
        };
      }
    }

    next();
  } catch (error) {
    // Continue without user for optional auth
    next();
  }
};

// Require premium subscription
export const requirePremium = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  if (!req.user) {
    ResponseService.unauthorized(res, 'Authentication required');
    return;
  }

  if (!req.user.isPremium) {
    ResponseService.forbidden(res, 'Premium subscription required');
    return;
  }

  next();
};

// Check if user owns the resource
export const checkResourceOwnership = (
  resourceType: 'studySession' | 'subject' | 'task' | 'analytics'
) => {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        ResponseService.unauthorized(res, 'Authentication required');
        return;
      }

      const resourceId = req.params.id;
      if (!resourceId) {
        ResponseService.badRequest(res, 'Resource ID required');
        return;
      }

      const pool = getDatabasePool();
      let query: string;
      let result: any;

      switch (resourceType) {
        case 'studySession':
          query = 'SELECT user_id FROM study_sessions WHERE id = $1';
          result = await pool.query(query, [resourceId]);
          break;
        case 'subject':
          query = 'SELECT user_id FROM subjects WHERE id = $1';
          result = await pool.query(query, [resourceId]);
          break;
        case 'task':
          query = 'SELECT user_id FROM study_tasks WHERE id = $1';
          result = await pool.query(query, [resourceId]);
          break;
        case 'analytics':
          // Analytics are user-specific, so we check if the requested user ID matches
          const requestedUserId = req.params.userId || req.query.userId;
          if (requestedUserId !== req.user.id) {
            ResponseService.forbidden(res, 'Access denied to this resource');
            return;
          }
          next();
          return;
        default:
          ResponseService.badRequest(res, 'Invalid resource type');
          return;
      }

      if (result.rows.length === 0) {
        ResponseService.notFound(res, 'Resource not found');
        return;
      }

      if (result.rows[0].user_id !== req.user.id) {
        ResponseService.forbidden(res, 'Access denied to this resource');
        return;
      }

      next();
    } catch (error) {
      ResponseService.internalError(res, 'Error checking resource ownership');
    }
  };
};

// Rate limiting based on user tier
export const tierBasedRateLimit = (
  freeTierLimit: number,
  premiumLimit: number,
  windowMs: number
) => {
  const userRequests = new Map<string, { count: number; resetTime: number }>();

  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      ResponseService.unauthorized(res, 'Authentication required');
      return;
    }

    const userId = req.user.id;
    const now = Date.now();
    const limit = req.user.isPremium ? premiumLimit : freeTierLimit;

    const userRecord = userRequests.get(userId);

    if (!userRecord || now > userRecord.resetTime) {
      // Reset or initialize user record
      userRequests.set(userId, {
        count: 1,
        resetTime: now + windowMs
      });
      next();
      return;
    }

    if (userRecord.count >= limit) {
      const resetIn = Math.ceil((userRecord.resetTime - now) / 1000);
      res.set('Retry-After', resetIn.toString());
      ResponseService.rateLimitExceeded(res, resetIn);
      return;
    }

    userRecord.count++;
    next();
  };
};