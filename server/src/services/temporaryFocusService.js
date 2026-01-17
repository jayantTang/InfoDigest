/**
 * Temporary Focus Service for v2.0
 * Handles temporary focus monitoring
 */

import { pool } from '../config/database.js';
import logger from '../config/logger.js';
import { validateTemporaryFocus } from '../utils/validators.js';

/**
 * Get all temporary focus items for a user
 * @param {string} userId - User UUID
 * @param {Object} filters - Optional filters
 * @returns {Promise<Array>} Array of temporary focus items
 */
export const getUserTemporaryFocus = async (userId, filters = {}) => {
  try {
    let query = `
      SELECT
        id,
        user_id,
        title,
        description,
        targets,
        focus,
        expires_at,
        status,
        findings,
        created_at,
        updated_at
      FROM temporary_focus
      WHERE user_id = $1
    `;

    const values = [userId];
    let paramIndex = 2;

    // Apply filters
    if (filters.status) {
      query += ` AND status = $${paramIndex}`;
      values.push(filters.status);
      paramIndex++;
    }

    // Also show expired items that are still monitoring
    query += ' ORDER BY created_at DESC';

    const result = await pool.query(query, values);

    return result.rows;
  } catch (error) {
    logger.error('Error getting user temporary focus', {
      error: error.message,
      userId,
    });
    throw error;
  }
};

/**
 * Get temporary focus by ID
 * @param {string} focusId - Temporary focus UUID
 * @param {string} userId - User UUID
 * @returns {Promise<Object|null>} Temporary focus object or null
 */
export const getTemporaryFocusById = async (focusId, userId) => {
  try {
    const query = `
      SELECT * FROM temporary_focus
      WHERE id = $1 AND user_id = $2
      LIMIT 1
    `;

    const result = await pool.query(query, [focusId, userId]);

    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0];
  } catch (error) {
    logger.error('Error getting temporary focus by ID', {
      error: error.message,
      focusId,
    });
    throw error;
  }
};

/**
 * Create temporary focus
 * @param {string} userId - User UUID
 * @param {Object} focusData - Temporary focus data
 * @returns {Promise<Object>} Created temporary focus
 */
export const createTemporaryFocus = async (userId, focusData) => {
  try {
    const validation = validateTemporaryFocus(focusData);

    if (!validation.valid) {
      throw new Error(`Invalid temporary focus data: ${validation.errors.join(', ')}`);
    }

    const {
      title,
      description,
      targets,
      focus,
      expiresAt,
    } = focusData;

    const query = `
      INSERT INTO temporary_focus (
        user_id,
        title,
        description,
        targets,
        focus,
        expires_at,
        status
      ) VALUES (
        $1, $2, $3, $4, $5, $6, 'monitoring'
      )
      RETURNING *
    `;

    const result = await pool.query(query, [
      userId,
      title,
      description || null,
      JSON.stringify(targets),
      JSON.stringify(focus || {}),
      expiresAt,
    ]);

    logger.info('Temporary focus created', {
      focusId: result.rows[0].id,
      userId,
      title,
      expiresAt,
    });

    return result.rows[0];
  } catch (error) {
    logger.error('Error creating temporary focus', {
      error: error.message,
      userId,
    });
    throw error;
  }
};

/**
 * Update temporary focus
 * @param {string} focusId - Temporary focus UUID
 * @param {string} userId - User UUID
 * @param {Object} updates - Fields to update
 * @returns {Promise<Object>} Updated temporary focus
 */
export const updateTemporaryFocus = async (focusId, userId, updates) => {
  try {
    const allowedFields = [
      'title',
      'description',
      'targets',
      'focus',
      'expiresAt',
      'status',
      'findings',
    ];

    const updateFields = [];
    const values = [focusId, userId];
    let paramIndex = 3;

    for (const [key, value] of Object.entries(updates)) {
      if (allowedFields.includes(key)) {
        // Convert camelCase to snake_case for DB
        const dbField = key.replace(/([A-Z])/g, '_$1').toLowerCase();

        updateFields.push(`${dbField} = $${paramIndex}`);

        if (key === 'targets' || key === 'focus' || key === 'findings') {
          values.push(JSON.stringify(value));
        } else {
          values.push(value);
        }

        paramIndex++;
      }
    }

    if (updateFields.length === 0) {
      throw new Error('No valid fields to update');
    }

    const query = `
      UPDATE temporary_focus
      SET
        ${updateFields.join(', ')},
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND user_id = $2
      RETURNING *
    `;

    const result = await pool.query(query, values);

    if (result.rows.length === 0) {
      throw new Error('Temporary focus not found');
    }

    logger.info('Temporary focus updated', {
      focusId,
      userId,
      updates: Object.keys(updates),
    });

    return result.rows[0];
  } catch (error) {
    logger.error('Error updating temporary focus', {
      error: error.message,
      focusId,
    });
    throw error;
  }
};

/**
 * Delete temporary focus
 * @param {string} focusId - Temporary focus UUID
 * @param {string} userId - User UUID
 * @returns {Promise<boolean>} True if deleted
 */
export const deleteTemporaryFocus = async (focusId, userId) => {
  try {
    const query = `
      DELETE FROM temporary_focus
      WHERE id = $1 AND user_id = $2
      RETURNING id
    `;

    const result = await pool.query(query, [focusId, userId]);

    if (result.rows.length === 0) {
      throw new Error('Temporary focus not found');
    }

    logger.info('Temporary focus deleted', {
      focusId,
      userId,
    });

    return true;
  } catch (error) {
    logger.error('Error deleting temporary focus', {
      error: error.message,
      focusId,
    });
    throw error;
  }
};

/**
 * Get active temporary focus for monitoring
 * Called by monitoring service
 * @returns {Promise<Array>} Array of active temporary focus items
 */
export const getActiveTemporaryFocus = async () => {
  try {
    const query = `
      SELECT
        tf.id,
        tf.user_id,
        tf.title,
        tf.targets,
        tf.focus,
        tf.expires_at,
        u.push_token,
        u.preferences
      FROM temporary_focus tf
      JOIN users u ON tf.user_id = u.id
      WHERE tf.status = 'monitoring'
        AND tf.expires_at > CURRENT_TIMESTAMP
        AND u.push_enabled = true
        AND u.push_token IS NOT NULL
      ORDER BY tf.created_at DESC
    `;

    const result = await pool.query(query);

    return result.rows;
  } catch (error) {
    logger.error('Error getting active temporary focus', {
      error: error.message,
    });
    throw error;
  }
};

/**
 * Mark expired temporary focus as completed
 * Called by scheduled task
 * @returns {Promise<number>} Number of items marked as completed
 */
export const markExpiredTemporaryFocus = async () => {
  try {
    const query = `
      UPDATE temporary_focus
      SET status = 'completed',
        updated_at = CURRENT_TIMESTAMP
      WHERE status = 'monitoring'
        AND expires_at <= CURRENT_TIMESTAMP
      RETURNING id
    `;

    const result = await pool.query(query);

    const count = result.rows.length;

    if (count > 0) {
      logger.info('Expired temporary focus marked as completed', {
        count,
        ids: result.rows.map((r) => r.id),
      });
    }

    return count;
  } catch (error) {
    logger.error('Error marking expired temporary focus', {
      error: error.message,
    });
    throw error;
  }
};

/**
 * Update temporary focus findings
 * @param {string} focusId - Temporary focus UUID
 * @param {Object} findings - Analysis findings
 * @returns {Promise<Object>} Updated temporary focus
 */
export const updateTemporaryFocusFindings = async (focusId, findings) => {
  try {
    const query = `
      UPDATE temporary_focus
      SET
        findings = COALESCE(findings, '{}'::jsonb) || $2::jsonb,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `;

    const result = await pool.query(query, [focusId, JSON.stringify(findings)]);

    if (result.rows.length === 0) {
      throw new Error('Temporary focus not found');
    }

    logger.info('Temporary focus findings updated', {
      focusId,
      findingsKeys: Object.keys(findings),
    });

    return result.rows[0];
  } catch (error) {
    logger.error('Error updating temporary focus findings', {
      error: error.message,
      focusId,
    });
    throw error;
  }
};

export default {
  getUserTemporaryFocus,
  getTemporaryFocusById,
  createTemporaryFocus,
  updateTemporaryFocus,
  deleteTemporaryFocus,
  getActiveTemporaryFocus,
  markExpiredTemporaryFocus,
  updateTemporaryFocusFindings,
};
