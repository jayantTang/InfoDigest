/**
 * User Routes for v2.0
 * Handles user registration and profile management
 */

import express from 'express';
import {
  registerOrUpdateUser,
  getUserById,
  updateUserPreferences,
  updateUserProfile,
  deleteUser,
  getUserStats,
} from '../services/userService.js';
import { requireDeviceToken, requireUser } from '../middleware/auth.js';
import { responseHelpers, successResponse } from '../middleware/responseFormatter.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import logger from '../config/logger.js';

const router = express.Router();

// Apply response helpers middleware
router.use(responseHelpers);

/**
 * POST /api/users/register
 * Register new user or update existing user
 *
 * Request body:
 * {
 *   "deviceToken": "uuid",
 *   "platform": "ios" | "android",
 *   "initialConfig": {
 *     "portfolio": [...],
 *     "watchlist": [...],
 *     "preferences": {...}
 *   }
 * }
 */
router.post(
  '/register',
  asyncHandler(async (req, res) => {
    const { deviceToken, platform, initialConfig } = req.body;

    if (!deviceToken) {
      return res.error('deviceToken is required', 400);
    }

    if (!platform) {
      return res.error('platform is required', 400);
    }

    const validPlatforms = ['ios', 'android'];
    if (!validPlatforms.includes(platform)) {
      return res.error('platform must be ios or android', 400);
    }

    const user = await registerOrUpdateUser({
      deviceToken,
      platform,
      initialConfig,
    });

    logger.info('User registered/updated', {
      userId: user.id,
      platform,
    });

    return res.success(
      {
        user: {
          id: user.id,
          email: user.email,
          preferences: user.preferences,
          createdAt: user.created_at,
        },
      },
      200
    );
  })
);

/**
 * GET /api/users/profile
 * Get current user profile
 * Requires authentication
 */
router.get(
  '/profile',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const user = await getUserById(req.userId);

    if (!user) {
      return res.error('User not found', 404);
    }

    return res.success({
      user: {
        id: user.id,
        email: user.email,
        pushEnabled: user.push_enabled,
        preferences: user.preferences,
        learnedProfile: user.learned_profile,
        createdAt: user.created_at,
        updatedAt: user.updated_at,
        lastActiveAt: user.last_active_at,
      },
    });
  })
);

/**
 * PUT /api/users/profile
 * Update user profile
 * Requires authentication
 *
 * Request body:
 * {
 *   "email": "new@example.com",
 *   "pushEnabled": true
 * }
 */
router.put(
  '/profile',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const updates = req.body;

    const user = await updateUserProfile(req.userId, updates);

    logger.info('User profile updated', {
      userId: req.userId,
      updates: Object.keys(updates),
    });

    return res.success({
      user: {
        id: user.id,
        email: user.email,
        pushEnabled: user.push_enabled,
        updatedAt: user.updated_at,
      },
    });
  })
);

/**
 * PUT /api/users/preferences
 * Update user preferences
 * Requires authentication
 *
 * Request body:
 * {
 *   "analysisLength": "full" | "summary",
 *   "pushFrequency": "minimal" | "normal" | "all",
 *   "quietHours": {
 *     "enabled": true,
 *     "start": "22:00",
 *     "end": "08:00"
 *   },
 *   "riskProfile": "conservative" | "neutral" | "aggressive",
 *   "contentTypes": {
 *     "stocks": true,
 *     "crypto": true,
 *     "news": true,
 *     "technical": true,
 *     "fundamental": true
 *   }
 * }
 */
router.put(
  '/preferences',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const preferences = req.body;

    const user = await updateUserPreferences(req.userId, preferences);

    logger.info('User preferences updated', {
      userId: req.userId,
      preferences: Object.keys(preferences),
    });

    return res.success({
      preferences: user.preferences,
      updatedAt: user.updated_at,
    });
  })
);

/**
 * GET /api/users/stats
 * Get user statistics
 * Requires authentication
 */
router.get(
  '/stats',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    const stats = await getUserStats(req.userId);

    return res.success(stats);
  })
);

/**
 * DELETE /api/users/account
 * Delete user account
 * Requires authentication
 * WARNING: This will cascade delete all user data
 */
router.delete(
  '/account',
  requireDeviceToken,
  requireUser,
  asyncHandler(async (req, res) => {
    await deleteUser(req.userId);

    logger.info('User account deleted', {
      userId: req.userId,
    });

    return res.success(
      {
        message: 'Account deleted successfully',
      },
      200
    );
  })
);

export default router;
