/**
 * Device Routes for v2.0
 * Handles device registration (now forwards to users API)
 *
 * NOTE: In v2.0, device management is integrated into user management.
 * This route exists for backward compatibility with v1.0 clients.
 */

import express from 'express';
import { registerOrUpdateUser } from '../services/userService.js';
import { responseHelpers } from '../middleware/responseFormatter.js';
import { asyncHandler } from '../middleware/errorHandler.js';
import logger from '../config/logger.js';

const router = express.Router();

// Apply response helpers middleware
router.use(responseHelpers);

/**
 * POST /api/devices/register
 * Register device (v2.0: creates/updates user)
 *
 * Backward compatible endpoint that forwards to /api/users/register
 *
 * Request body:
 * {
 *   "deviceToken": "uuid",
 *   "platform": "ios" | "android",
 *   "appVersion": "1.0.0",
 *   "osVersion": "17.0",
 *   "initialConfig": {...}
 * }
 */
router.post(
  '/register',
  asyncHandler(async (req, res) => {
    const { deviceToken, platform, appVersion, osVersion, initialConfig } = req.body;

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

    // Register or update user
    const user = await registerOrUpdateUser({
      deviceToken,
      platform,
      initialConfig,
    });

    logger.info('Device registered via v2 API', {
      userId: user.id,
      platform,
      appVersion,
    });

    // Backward compatible response format
    return res.success({
      deviceId: user.device_id,
      deviceToken: user.push_token,
      platform,
      userId: user.id,
      // v2.0 additions
      user: {
        id: user.id,
        email: user.email,
        preferences: user.preferences,
        createdAt: user.created_at,
      },
    });
  })
);

/**
 * GET /api/devices/:deviceId/info
 * Get device/user info (backward compatible)
 *
 * NOTE: In v2.0, use /api/users/profile instead
 */
router.get(
  '/:deviceId/info',
  asyncHandler(async (req, res) => {
    const { getUserByDeviceToken } = await import('../services/userService.js');

    // Get device token from header (required)
    const deviceToken = req.headers['x-device-token'];

    if (!deviceToken) {
      return res.error('x-device-token header is required', 401);
    }

    const user = await getUserByDeviceToken(deviceToken);

    if (!user) {
      return res.error('Device not found', 404);
    }

    return res.success({
      deviceId: user.device_id,
      deviceToken: user.push_token,
      pushEnabled: user.push_enabled,
      lastActiveAt: user.last_active_at,
      user: {
        id: user.id,
        email: user.email,
        preferences: user.preferences,
      },
    });
  })
);

export default router;
