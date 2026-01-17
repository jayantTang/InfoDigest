/**
 * Strategy Service for v2.0
 * Handles investment strategy management
 */

import { pool } from '../config/database.js';
import logger from '../config/logger.js';
import { validateStrategy } from '../utils/validators.js';

/**
 * Get all strategies for a user
 * @param {string} userId - User UUID
 * @param {Object} filters - Optional filters
 * @returns {Promise<Array>} Array of strategies
 */
export const getUserStrategies = async (userId, filters = {}) => {
  try {
    let query = `
      SELECT
        id,
        user_id,
        name,
        description,
        symbol,
        condition_type,
        conditions,
        action,
        reasoning,
        status,
        priority,
        last_triggered_at,
        trigger_count,
        created_at,
        updated_at
      FROM strategies
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

    if (filters.symbol) {
      query += ` AND symbol = $${paramIndex}`;
      values.push(filters.symbol.toUpperCase());
      paramIndex++;
    }

    if (filters.conditionType) {
      query += ` AND condition_type = $${paramIndex}`;
      values.push(filters.conditionType);
      paramIndex++;
    }

    query += ' ORDER BY priority DESC, created_at DESC';

    const result = await pool.query(query, values);

    return result.rows;
  } catch (error) {
    logger.error('Error getting user strategies', {
      error: error.message,
      userId,
    });
    throw error;
  }
};

/**
 * Get strategy by ID
 * @param {string} strategyId - Strategy UUID
 * @param {string} userId - User UUID
 * @returns {Promise<Object|null>} Strategy object or null
 */
export const getStrategyById = async (strategyId, userId) => {
  try {
    const query = `
      SELECT * FROM strategies
      WHERE id = $1 AND user_id = $2
      LIMIT 1
    `;

    const result = await pool.query(query, [strategyId, userId]);

    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0];
  } catch (error) {
    logger.error('Error getting strategy by ID', {
      error: error.message,
      strategyId,
    });
    throw error;
  }
};

/**
 * Create strategy
 * @param {string} userId - User UUID
 * @param {Object} strategyData - Strategy data
 * @returns {Promise<Object>} Created strategy
 */
export const createStrategy = async (userId, strategyData) => {
  try {
    const validation = validateStrategy(strategyData);

    if (!validation.valid) {
      throw new Error(`Invalid strategy data: ${validation.errors.join(', ')}`);
    }

    const {
      name,
      description,
      symbol,
      conditionType,
      conditions,
      action,
      reasoning,
      priority,
    } = strategyData;

    const query = `
      INSERT INTO strategies (
        user_id,
        name,
        description,
        symbol,
        condition_type,
        conditions,
        action,
        reasoning,
        priority
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9
      )
      RETURNING *
    `;

    const result = await pool.query(query, [
      userId,
      name,
      description || null,
      symbol.toUpperCase(),
      conditionType,
      JSON.stringify(conditions),
      JSON.stringify(action),
      reasoning || null,
      priority || 5,
    ]);

    logger.info('Strategy created', {
      strategyId: result.rows[0].id,
      userId,
      name,
      symbol,
    });

    return result.rows[0];
  } catch (error) {
    logger.error('Error creating strategy', {
      error: error.message,
      userId,
    });
    throw error;
  }
};

/**
 * Update strategy
 * @param {string} strategyId - Strategy UUID
 * @param {string} userId - User UUID
 * @param {Object} updates - Fields to update
 * @returns {Promise<Object>} Updated strategy
 */
export const updateStrategy = async (strategyId, userId, updates) => {
  try {
    const allowedFields = [
      'name',
      'description',
      'conditions',
      'action',
      'reasoning',
      'status',
      'priority',
    ];

    const updateFields = [];
    const values = [strategyId, userId];
    let paramIndex = 3;

    for (const [key, value] of Object.entries(updates)) {
      if (allowedFields.includes(key)) {
        updateFields.push(`${key} = $${paramIndex}`);

        if (key === 'conditions' || key === 'action') {
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
      UPDATE strategies
      SET
        ${updateFields.join(', ')},
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND user_id = $2
      RETURNING *
    `;

    const result = await pool.query(query, values);

    if (result.rows.length === 0) {
      throw new Error('Strategy not found');
    }

    logger.info('Strategy updated', {
      strategyId,
      userId,
      updates: Object.keys(updates),
    });

    return result.rows[0];
  } catch (error) {
    logger.error('Error updating strategy', {
      error: error.message,
      strategyId,
    });
    throw error;
  }
};

/**
 * Delete strategy
 * @param {string} strategyId - Strategy UUID
 * @param {string} userId - User UUID
 * @returns {Promise<boolean>} True if deleted
 */
export const deleteStrategy = async (strategyId, userId) => {
  try {
    const query = `
      DELETE FROM strategies
      WHERE id = $1 AND user_id = $2
      RETURNING id
    `;

    const result = await pool.query(query, [strategyId, userId]);

    if (result.rows.length === 0) {
      throw new Error('Strategy not found');
    }

    logger.info('Strategy deleted', {
      strategyId,
      userId,
    });

    return true;
  } catch (error) {
    logger.error('Error deleting strategy', {
      error: error.message,
      strategyId,
    });
    throw error;
  }
};

/**
 * Get active strategies for monitoring
 * Called by monitoring service to check triggers
 * @returns {Promise<Array>} Array of active strategies with user info
 */
export const getActiveStrategies = async () => {
  try {
    const query = `
      SELECT
        s.id,
        s.user_id,
        s.name,
        s.symbol,
        s.condition_type,
        s.conditions,
        s.action,
        s.priority,
        u.push_token,
        u.preferences
      FROM strategies s
      JOIN users u ON s.user_id = u.id
      WHERE s.status = 'active'
        AND u.push_enabled = true
        AND u.push_token IS NOT NULL
      ORDER BY s.priority DESC
    `;

    const result = await pool.query(query);

    return result.rows;
  } catch (error) {
    logger.error('Error getting active strategies', {
      error: error.message,
    });
    throw error;
  }
};

/**
 * Record strategy trigger
 * @param {string} strategyId - Strategy UUID
 * @param {string} userId - User UUID
 * @param {Object} triggerData - Trigger data
 * @returns {Promise<Object>} Created trigger record
 */
export const recordStrategyTrigger = async (
  strategyId,
  userId,
  triggerData
) => {
  try {
    const { triggerReason, marketData, analysisId } = triggerData;

    const query = `
      INSERT INTO strategy_triggers (
        strategy_id,
        user_id,
        triggered_at,
        trigger_reason,
        market_data,
        analysis_id
      ) VALUES (
        $1, $2, CURRENT_TIMESTAMP, $3, $4, $5
      )
      RETURNING *
    `;

    const result = await pool.query(query, [
      strategyId,
      userId,
      triggerReason,
      JSON.stringify(marketData),
      analysisId || null,
    ]);

    // Update strategy trigger count
    await pool.query(
      `
      UPDATE strategies
      SET
        last_triggered_at = CURRENT_TIMESTAMP,
        trigger_count = trigger_count + 1
      WHERE id = $1
    `,
      [strategyId]
    );

    logger.info('Strategy trigger recorded', {
      strategyId,
      userId,
      triggerReason,
    });

    return result.rows[0];
  } catch (error) {
    logger.error('Error recording strategy trigger', {
      error: error.message,
      strategyId,
    });
    throw error;
  }
};

/**
 * Get strategy triggers
 * @param {string} strategyId - Strategy UUID
 * @param {string} userId - User UUID
 * @param {number} limit - Number of triggers to return
 * @returns {Promise<Array>} Array of triggers
 */
export const getStrategyTriggers = async (strategyId, userId, limit = 10) => {
  try {
    const query = `
      SELECT
        st.id,
        st.triggered_at,
        st.trigger_reason,
        st.market_data,
        st.user_action,
        st.user_feedback,
        a.summary as analysis_summary
      FROM strategy_triggers st
      LEFT JOIN analyses a ON st.analysis_id = a.id
      WHERE st.strategy_id = $1
        AND st.user_id = $2
      ORDER BY st.triggered_at DESC
      LIMIT $3
    `;

    const result = await pool.query(query, [strategyId, userId, limit]);

    return result.rows;
  } catch (error) {
    logger.error('Error getting strategy triggers', {
      error: error.message,
      strategyId,
    });
    throw error;
  }
};

/**
 * Update strategy trigger with user feedback
 * @param {string} triggerId - Trigger UUID
 * @param {string} userId - User UUID
 * @param {Object} feedback - User feedback
 * @returns {Promise<Object>} Updated trigger
 */
export const updateTriggerFeedback = async (triggerId, userId, feedback) => {
  try {
    const query = `
      UPDATE strategy_triggers
      SET
        user_action = $2,
        user_feedback = $3
      WHERE id = $1 AND user_id = $4
      RETURNING *
    `;

    const result = await pool.query(query, [
      triggerId,
      feedback.action,
      feedback.feedback || null,
      userId,
    ]);

    if (result.rows.length === 0) {
      throw new Error('Trigger not found');
    }

    logger.info('Trigger feedback updated', {
      triggerId,
      userId,
      action: feedback.action,
    });

    return result.rows[0];
  } catch (error) {
    logger.error('Error updating trigger feedback', {
      error: error.message,
      triggerId,
    });
    throw error;
  }
};

export default {
  getUserStrategies,
  getStrategyById,
  createStrategy,
  updateStrategy,
  deleteStrategy,
  getActiveStrategies,
  recordStrategyTrigger,
  getStrategyTriggers,
  updateTriggerFeedback,
};
