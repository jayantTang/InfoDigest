/**
 * Watchlist Service for v2.0
 * Handles watchlist management
 */

import { pool } from '../config/database.js';
import logger from '../config/logger.js';
import { validateWatchlist } from '../utils/validators.js';

/**
 * Get all watchlist items for a user
 * @param {string} userId - User UUID
 * @param {Object} filters - Optional filters
 * @returns {Promise<Array>} Array of watchlist items
 */
export const getUserWatchlists = async (userId, filters = {}) => {
  try {
    let query = `
      SELECT
        id,
        user_id,
        symbol,
        asset_type,
        exchange,
        reason,
        notes,
        focus,
        priority,
        created_at,
        updated_at
      FROM watchlists
      WHERE user_id = $1
    `;

    const values = [userId];
    let paramIndex = 2;

    // Apply filters
    if (filters.assetType) {
      query += ` AND asset_type = $${paramIndex}`;
      values.push(filters.assetType);
      paramIndex++;
    }

    if (filters.reason) {
      query += ` AND reason = $${paramIndex}`;
      values.push(filters.reason);
      paramIndex++;
    }

    query += ' ORDER BY priority DESC, created_at DESC';

    const result = await pool.query(query, values);

    return result.rows;
  } catch (error) {
    logger.error('Error getting user watchlists', {
      error: error.message,
      userId,
    });
    throw error;
  }
};

/**
 * Get watchlist by ID
 * @param {string} watchlistId - Watchlist UUID
 * @param {string} userId - User UUID
 * @returns {Promise<Object|null>} Watchlist object or null
 */
export const getWatchlistById = async (watchlistId, userId) => {
  try {
    const query = `
      SELECT * FROM watchlists
      WHERE id = $1 AND user_id = $2
      LIMIT 1
    `;

    const result = await pool.query(query, [watchlistId, userId]);

    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0];
  } catch (error) {
    logger.error('Error getting watchlist by ID', {
      error: error.message,
      watchlistId,
    });
    throw error;
  }
};

/**
 * Get watchlist by symbol
 * @param {string} userId - User UUID
 * @param {string} symbol - Asset symbol
 * @returns {Promise<Object|null>} Watchlist object or null
 */
export const getWatchlistBySymbol = async (userId, symbol) => {
  try {
    const query = `
      SELECT * FROM watchlists
      WHERE user_id = $1 AND symbol = $2
      LIMIT 1
    `;

    const result = await pool.query(query, [userId, symbol]);

    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0];
  } catch (error) {
    logger.error('Error getting watchlist by symbol', {
      error: error.message,
      userId,
      symbol,
    });
    throw error;
  }
};

/**
 * Create watchlist item
 * @param {string} userId - User UUID
 * @param {Object} watchlistData - Watchlist data
 * @returns {Promise<Object>} Created watchlist
 */
export const createWatchlist = async (userId, watchlistData) => {
  try {
    const validation = validateWatchlist(watchlistData);

    if (!validation.valid) {
      throw new Error(`Invalid watchlist data: ${validation.errors.join(', ')}`);
    }

    const {
      symbol,
      assetType,
      exchange,
      reason,
      notes,
      focus,
      priority,
    } = watchlistData;

    const query = `
      INSERT INTO watchlists (
        user_id,
        symbol,
        asset_type,
        exchange,
        reason,
        notes,
        focus,
        priority
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8
      )
      RETURNING *
    `;

    const result = await pool.query(query, [
      userId,
      symbol.toUpperCase(),
      assetType,
      exchange || null,
      reason || null,
      notes || null,
      JSON.stringify(focus || {}),
      priority || 5,
    ]);

    logger.info('Watchlist item created', {
      watchlistId: result.rows[0].id,
      userId,
      symbol,
    });

    return result.rows[0];
  } catch (error) {
    if (error.code === '23505') {
      // Unique violation
      throw new Error('Symbol already in watchlist');
    }

    logger.error('Error creating watchlist', {
      error: error.message,
      userId,
    });
    throw error;
  }
};

/**
 * Update watchlist item
 * @param {string} watchlistId - Watchlist UUID
 * @param {string} userId - User UUID
 * @param {Object} updates - Fields to update
 * @returns {Promise<Object>} Updated watchlist
 */
export const updateWatchlist = async (watchlistId, userId, updates) => {
  try {
    const allowedFields = ['reason', 'notes', 'focus', 'priority'];

    const updateFields = [];
    const values = [watchlistId, userId];
    let paramIndex = 3;

    for (const [key, value] of Object.entries(updates)) {
      if (allowedFields.includes(key)) {
        updateFields.push(`${key} = $${paramIndex}`);

        if (key === 'focus') {
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
      UPDATE watchlists
      SET
        ${updateFields.join(', ')},
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND user_id = $2
      RETURNING *
    `;

    const result = await pool.query(query, values);

    if (result.rows.length === 0) {
      throw new Error('Watchlist item not found');
    }

    logger.info('Watchlist item updated', {
      watchlistId,
      userId,
      updates: Object.keys(updates),
    });

    return result.rows[0];
  } catch (error) {
    logger.error('Error updating watchlist', {
      error: error.message,
      watchlistId,
    });
    throw error;
  }
};

/**
 * Delete watchlist item
 * @param {string} watchlistId - Watchlist UUID
 * @param {string} userId - User UUID
 * @returns {Promise<boolean>} True if deleted
 */
export const deleteWatchlist = async (watchlistId, userId) => {
  try {
    const query = `
      DELETE FROM watchlists
      WHERE id = $1 AND user_id = $2
      RETURNING id
    `;

    const result = await pool.query(query, [watchlistId, userId]);

    if (result.rows.length === 0) {
      throw new Error('Watchlist item not found');
    }

    logger.info('Watchlist item deleted', {
      watchlistId,
      userId,
    });

    return true;
  } catch (error) {
    logger.error('Error deleting watchlist', {
      error: error.message,
      watchlistId,
    });
    throw error;
  }
};

/**
 * Get watchlist summary
 * @param {string} userId - User UUID
 * @returns {Promise<Object>} Watchlist summary
 */
export const getWatchlistSummary = async (userId) => {
  try {
    const query = `
      SELECT
        COUNT(*) as total_count,
        COUNT(CASE WHEN reason = 'potential_buy' THEN 1 END) as potential_buy_count,
        COUNT(CASE WHEN reason = 'competitor' THEN 1 END) as competitor_count,
        COUNT(CASE WHEN reason = 'sector_watch' THEN 1 END) as sector_watch_count,
        COUNT(CASE WHEN reason = 'speculative' THEN 1 END) as speculative_count
      FROM watchlists
      WHERE user_id = $1
    `;

    const result = await pool.query(query, [userId]);
    const row = result.rows[0];

    return {
      totalCount: parseInt(row.total_count) || 0,
      potentialBuyCount: parseInt(row.potential_buy_count) || 0,
      competitorCount: parseInt(row.competitor_count) || 0,
      sectorWatchCount: parseInt(row.sector_watch_count) || 0,
      speculativeCount: parseInt(row.speculative_count) || 0,
    };
  } catch (error) {
    logger.error('Error getting watchlist summary', {
      error: error.message,
      userId,
    });
    throw error;
  }
};

export default {
  getUserWatchlists,
  getWatchlistById,
  getWatchlistBySymbol,
  createWatchlist,
  updateWatchlist,
  deleteWatchlist,
  getWatchlistSummary,
};
