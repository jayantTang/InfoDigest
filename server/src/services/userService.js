/**
 * User Service for v2.0
 * Handles user-related database operations
 */

import { pool } from '../config/database.js';
import logger from '../config/logger.js';
import { validatePreferences } from '../utils/validators.js';

/**
 * Get user by device token
 * @param {string} deviceToken - Device token from APNs
 * @returns {Promise<Object|null>} User object or null
 */
export const getUserByDeviceToken = async (deviceToken) => {
  try {
    const query = `
      SELECT
        id,
        email,
        device_id,
        push_enabled,
        push_token,
        preferences,
        learned_profile,
        created_at,
        updated_at,
        last_active_at
      FROM users
      WHERE push_token = $1
      LIMIT 1
    `;

    const result = await pool.query(query, [deviceToken]);

    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0];
  } catch (error) {
    logger.error('Error getting user by device token', {
      error: error.message,
      deviceToken: deviceToken.substring(0, 10) + '...',
    });
    throw error;
  }
};

/**
 * Get user by ID
 * @param {string} userId - User UUID
 * @returns {Promise<Object|null>} User object or null
 */
export const getUserById = async (userId) => {
  try {
    const query = `
      SELECT
        id,
        email,
        device_id,
        push_enabled,
        push_token,
        preferences,
        learned_profile,
        created_at,
        updated_at,
        last_active_at
      FROM users
      WHERE id = $1
      LIMIT 1
    `;

    const result = await pool.query(query, [userId]);

    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0];
  } catch (error) {
    logger.error('Error getting user by ID', {
      error: error.message,
      userId,
    });
    throw error;
  }
};

/**
 * Register new user or update existing user
 * @param {Object} userData - User data
 * @param {string} userData.deviceToken - Device token
 * @param {string} userData.platform - Platform (ios, android)
 * @param {Object} userData.initialConfig - Initial configuration (optional)
 * @returns {Promise<Object>} Created/updated user
 */
export const registerOrUpdateUser = async (userData) => {
  const { deviceToken, platform, initialConfig } = userData;

  try {
    // Check if user exists
    const existingUser = await getUserByDeviceToken(deviceToken);

    if (existingUser) {
      // Update last_active_at
      const updateQuery = `
        UPDATE users
        SET
          last_active_at = CURRENT_TIMESTAMP,
          push_enabled = true,
          push_token = $1
        WHERE id = $2
        RETURNING *
      `;

      const result = await pool.query(updateQuery, [deviceToken, existingUser.id]);
      return result.rows[0];
    }

    // Create new user
    const preferences = initialConfig?.preferences || {};
    const validation = validatePreferences(preferences);

    if (!validation.valid) {
      throw new Error(`Invalid preferences: ${validation.errors.join(', ')}`);
    }

    const insertQuery = `
      INSERT INTO users (
        device_id,
        push_token,
        push_enabled,
        preferences,
        last_active_at
      ) VALUES (
        gen_random_uuid(),
        $1,
        true,
        $2,
        CURRENT_TIMESTAMP
      )
      RETURNING *
    `;

    const result = await pool.query(insertQuery, [
      deviceToken,
      JSON.stringify(preferences),
    ]);

    const newUser = result.rows[0];

    // If initial config includes portfolio, watchlist, or strategies
    // create them here (will be handled by respective services)

    logger.info('New user registered', {
      userId: newUser.id,
      platform,
    });

    return newUser;
  } catch (error) {
    logger.error('Error registering/updating user', {
      error: error.message,
      deviceToken: deviceToken.substring(0, 10) + '...',
    });
    throw error;
  }
};

/**
 * Update user preferences
 * @param {string} userId - User UUID
 * @param {Object} preferences - New preferences
 * @returns {Promise<Object>} Updated user
 */
export const updateUserPreferences = async (userId, preferences) => {
  try {
    const validation = validatePreferences(preferences);

    if (!validation.valid) {
      throw new Error(`Invalid preferences: ${validation.errors.join(', ')}`);
    }

    const query = `
      UPDATE users
      SET
        preferences = $2,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `;

    const result = await pool.query(query, [userId, JSON.stringify(preferences)]);

    if (result.rows.length === 0) {
      throw new Error('User not found');
    }

    return result.rows[0];
  } catch (error) {
    logger.error('Error updating user preferences', {
      error: error.message,
      userId,
    });
    throw error;
  }
};

/**
 * Update user profile
 * @param {string} userId - User UUID
 * @param {Object} updates - Fields to update
 * @returns {Promise<Object>} Updated user
 */
export const updateUserProfile = async (userId, updates) => {
  try {
    const allowedFields = ['email', 'push_enabled'];
    const updateFields = [];
    const values = [userId];
    let paramIndex = 2;

    for (const [key, value] of Object.entries(updates)) {
      if (allowedFields.includes(key)) {
        updateFields.push(`${key} = $${paramIndex}`);
        values.push(value);
        paramIndex++;
      }
    }

    if (updateFields.length === 0) {
      throw new Error('No valid fields to update');
    }

    const query = `
      UPDATE users
      SET
        ${updateFields.join(', ')},
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `;

    const result = await pool.query(query, values);

    if (result.rows.length === 0) {
      throw new Error('User not found');
    }

    return result.rows[0];
  } catch (error) {
    logger.error('Error updating user profile', {
      error: error.message,
      userId,
    });
    throw error;
  }
};

/**
 * Update learned profile (used by AI learning system)
 * @param {string} userId - User UUID
 * @param {Object} profileData - Profile data to update/merge
 * @returns {Promise<Object>} Updated user
 */
export const updateLearnedProfile = async (userId, profileData) => {
  try {
    const query = `
      UPDATE users
      SET
        learned_profile = COALESCE(learned_profile, '{}'::jsonb) || $2::jsonb,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `;

    const result = await pool.query(query, [userId, JSON.stringify(profileData)]);

    if (result.rows.length === 0) {
      throw new Error('User not found');
    }

    return result.rows[0];
  } catch (error) {
    logger.error('Error updating learned profile', {
      error: error.message,
      userId,
    });
    throw error;
  }
};

/**
 * Delete user account
 * @param {string} userId - User UUID
 * @returns {Promise<boolean>} True if deleted
 */
export const deleteUser = async (userId) => {
  try {
    const query = 'DELETE FROM users WHERE id = $1 RETURNING id';

    const result = await pool.query(query, [userId]);

    if (result.rows.length === 0) {
      throw new Error('User not found');
    }

    logger.info('User deleted', { userId });

    return true;
  } catch (error) {
    logger.error('Error deleting user', {
      error: error.message,
      userId,
    });
    throw error;
  }
};

/**
 * Get user statistics
 * @param {string} userId - User UUID
 * @returns {Promise<Object>} User statistics
 */
export const getUserStats = async (userId) => {
  try {
    const queries = await Promise.all([
      // Portfolio count
      pool.query(
        'SELECT COUNT(*) as count FROM portfolios WHERE user_id = $1 AND status = $2',
        [userId, 'active']
      ),
      // Watchlist count
      pool.query(
        'SELECT COUNT(*) as count FROM watchlists WHERE user_id = $1',
        [userId]
      ),
      // Active strategies count
      pool.query(
        'SELECT COUNT(*) as count FROM strategies WHERE user_id = $1 AND status = $2',
        [userId, 'active']
      ),
      // Total analyses count
      pool.query(
        'SELECT COUNT(*) as count FROM analyses WHERE user_id = $1',
        [userId]
      ),
    ]);

    return {
      portfolioCount: parseInt(queries[0].rows[0].count),
      watchlistCount: parseInt(queries[1].rows[0].count),
      activeStrategiesCount: parseInt(queries[2].rows[0].count),
      totalAnalysesCount: parseInt(queries[3].rows[0].count),
    };
  } catch (error) {
    logger.error('Error getting user stats', {
      error: error.message,
      userId,
    });
    throw error;
  }
};

export default {
  getUserByDeviceToken,
  getUserById,
  registerOrUpdateUser,
  updateUserPreferences,
  updateUserProfile,
  updateLearnedProfile,
  deleteUser,
  getUserStats,
};
