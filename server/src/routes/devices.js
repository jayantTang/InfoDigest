import express from 'express';
import { query } from '../config/database.js';
import { asyncHandler, AppError } from '../middleware/errorHandler.js';
import logger from '../config/logger.js';

const router = express.Router();

// Register device token
router.post(
  '/register',
  asyncHandler(async (req, res) => {
    const { deviceToken, platform = 'ios', appVersion, osVersion } = req.body;

    if (!deviceToken || !platform) {
      throw new AppError('deviceToken and platform are required', 400);
    }

    // Check if device exists
    const existingDevice = await query(
      'SELECT * FROM devices WHERE device_token = $1',
      [deviceToken]
    );

    let device;
    if (existingDevice.rows.length > 0) {
      // Update existing device
      const result = await query(
        `UPDATE devices
         SET last_used_at = CURRENT_TIMESTAMP,
             app_version = $2,
             os_version = $3,
             is_active = true
         WHERE device_token = $1
         RETURNING *`,
        [deviceToken, appVersion, osVersion]
      );
      device = result.rows[0];
      logger.info('Device updated', { deviceToken, platform });
    } else {
      // Create new device (and user)
      // First, try to create user, or use existing one
      const userEmail = `${deviceToken.substring(0, 20)}@device.local`;
      const userName = `user_${deviceToken.substring(0, 8)}`;

      const userResult = await query(
        `INSERT INTO users (email, username)
         VALUES ($1, $2)
         ON CONFLICT (email) DO UPDATE SET email = EXCLUDED.email
         RETURNING id`,
        [userEmail, userName]
      );

      const userId = userResult.rows[0].id;

      const client = await query(
        `INSERT INTO devices (user_id, device_token, platform, app_version, os_version)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [userId, deviceToken, platform, appVersion, osVersion]
      );
      device = client.rows[0];
      logger.info('New device registered', { deviceToken, platform });
    }

    res.json({
      success: true,
      data: {
        deviceId: device.id,
        deviceToken: device.device_token,
        platform: device.platform,
      },
    });
  })
);

// Update device preferences
router.put(
  '/:deviceId/preferences',
  asyncHandler(async (req, res) => {
    const { deviceId } = req.params;
    const { preferences } = req.body;

    // For now, we'll store preferences in the user table
    // In a real app, you might want a separate preferences table
    await query(
      `UPDATE devices
       SET config = COALESCE(config, '{}'::jsonb) || $2::jsonb
       WHERE id = $1`,
      [deviceId, JSON.stringify(preferences)]
    );

    res.json({ success: true, message: 'Preferences updated' });
  })
);

// Get device info
router.get(
  '/:deviceId',
  asyncHandler(async (req, res) => {
    const { deviceId } = req.params;

    const result = await query('SELECT * FROM devices WHERE id = $1', [deviceId]);

    if (result.rows.length === 0) {
      throw new AppError('Device not found', 404);
    }

    res.json({ success: true, data: result.rows[0] });
  })
);

export default router;
