/**
 * Portfolio Service for v2.0
 * Handles portfolio position management
 */

import { pool } from '../config/database.js';
import logger from '../config/logger.js';
import { validatePortfolio } from '../utils/validators.js';

/**
 * Get all portfolios for a user
 * @param {string} userId - User UUID
 * @param {Object} filters - Optional filters
 * @returns {Promise<Array>} Array of portfolio positions
 */
export const getUserPortfolios = async (userId, filters = {}) => {
  try {
    let query = `
      SELECT
        id,
        user_id,
        symbol,
        asset_type,
        exchange,
        shares,
        avg_cost,
        current_price,
        unrealized_pnl,
        total_value,
        opened_at,
        last_updated,
        alerts,
        status,
        created_at,
        updated_at
      FROM portfolios
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

    if (filters.assetType) {
      query += ` AND asset_type = $${paramIndex}`;
      values.push(filters.assetType);
      paramIndex++;
    }

    query += ' ORDER BY created_at DESC';

    const result = await pool.query(query, values);

    return result.rows;
  } catch (error) {
    logger.error('Error getting user portfolios', {
      error: error.message,
      userId,
    });
    throw error;
  }
};

/**
 * Get portfolio by ID
 * @param {string} portfolioId - Portfolio UUID
 * @param {string} userId - User UUID (for authorization)
 * @returns {Promise<Object|null>} Portfolio object or null
 */
export const getPortfolioById = async (portfolioId, userId) => {
  try {
    const query = `
      SELECT
        id,
        user_id,
        symbol,
        asset_type,
        exchange,
        shares,
        avg_cost,
        current_price,
        unrealized_pnl,
        total_value,
        opened_at,
        last_updated,
        alerts,
        status,
        created_at,
        updated_at
      FROM portfolios
      WHERE id = $1 AND user_id = $2
      LIMIT 1
    `;

    const result = await pool.query(query, [portfolioId, userId]);

    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0];
  } catch (error) {
    logger.error('Error getting portfolio by ID', {
      error: error.message,
      portfolioId,
    });
    throw error;
  }
};

/**
 * Get portfolio by symbol
 * @param {string} userId - User UUID
 * @param {string} symbol - Asset symbol
 * @returns {Promise<Object|null>} Portfolio object or null
 */
export const getPortfolioBySymbol = async (userId, symbol) => {
  try {
    const query = `
      SELECT * FROM portfolios
      WHERE user_id = $1 AND symbol = $2
      LIMIT 1
    `;

    const result = await pool.query(query, [userId, symbol]);

    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0];
  } catch (error) {
    logger.error('Error getting portfolio by symbol', {
      error: error.message,
      userId,
      symbol,
    });
    throw error;
  }
};

/**
 * Create new portfolio position
 * @param {string} userId - User UUID
 * @param {Object} portfolioData - Portfolio data
 * @returns {Promise<Object>} Created portfolio
 */
export const createPortfolio = async (userId, portfolioData) => {
  try {
    const validation = validatePortfolio(portfolioData);

    if (!validation.valid) {
      throw new Error(`Invalid portfolio data: ${validation.errors.join(', ')}`);
    }

    const {
      symbol,
      assetType,
      exchange,
      shares,
      avgCost,
      alerts,
    } = portfolioData;

    const query = `
      INSERT INTO portfolios (
        user_id,
        symbol,
        asset_type,
        exchange,
        shares,
        avg_cost,
        alerts
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7
      )
      RETURNING *
    `;

    const result = await pool.query(query, [
      userId,
      symbol.toUpperCase(),
      assetType,
      exchange || null,
      shares,
      avgCost,
      JSON.stringify(alerts || {}),
    ]);

    logger.info('Portfolio position created', {
      portfolioId: result.rows[0].id,
      userId,
      symbol,
    });

    return result.rows[0];
  } catch (error) {
    if (error.code === '23505') {
      // Unique violation
      throw new Error('Position for this symbol already exists');
    }

    logger.error('Error creating portfolio', {
      error: error.message,
      userId,
    });
    throw error;
  }
};

/**
 * Update portfolio position
 * @param {string} portfolioId - Portfolio UUID
 * @param {string} userId - User UUID
 * @param {Object} updates - Fields to update
 * @returns {Promise<Object>} Updated portfolio
 */
export const updatePortfolio = async (portfolioId, userId, updates) => {
  try {
    const allowedFields = [
      'shares',
      'avgCost',
      'currentPrice',
      'unrealizedPnl',
      'totalValue',
      'alerts',
      'status',
    ];

    const updateFields = [];
    const values = [portfolioId, userId];
    let paramIndex = 3;

    for (const [key, value] of Object.entries(updates)) {
      if (allowedFields.includes(key)) {
        // Convert camelCase to snake_case for DB
        const dbField = key.replace(/([A-Z])/g, '_$1').toLowerCase();

        updateFields.push(`${dbField} = $${paramIndex}`);

        if (key === 'alerts') {
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
      UPDATE portfolios
      SET
        ${updateFields.join(', ')},
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND user_id = $2
      RETURNING *
    `;

    const result = await pool.query(query, values);

    if (result.rows.length === 0) {
      throw new Error('Portfolio not found');
    }

    logger.info('Portfolio position updated', {
      portfolioId,
      userId,
      updates: Object.keys(updates),
    });

    return result.rows[0];
  } catch (error) {
    logger.error('Error updating portfolio', {
      error: error.message,
      portfolioId,
    });
    throw error;
  }
};

/**
 * Delete portfolio position
 * @param {string} portfolioId - Portfolio UUID
 * @param {string} userId - User UUID
 * @returns {Promise<boolean>} True if deleted
 */
export const deletePortfolio = async (portfolioId, userId) => {
  try {
    const query = `
      DELETE FROM portfolios
      WHERE id = $1 AND user_id = $2
      RETURNING id
    `;

    const result = await pool.query(query, [portfolioId, userId]);

    if (result.rows.length === 0) {
      throw new Error('Portfolio not found');
    }

    logger.info('Portfolio position deleted', {
      portfolioId,
      userId,
    });

    return true;
  } catch (error) {
    logger.error('Error deleting portfolio', {
      error: error.message,
      portfolioId,
    });
    throw error;
  }
};

/**
 * Update portfolio current prices (batch update)
 * Called by scheduled task to update market prices
 * @param {Array<Object>} priceUpdates - Array of {symbol, currentPrice}
 * @returns {Promise<number>} Number of portfolios updated
 */
export const updatePortfolioPrices = async (priceUpdates) => {
  try {
    let updatedCount = 0;

    for (const update of priceUpdates) {
      const query = `
        UPDATE portfolios
        SET
          current_price = $2,
          total_value = shares * $2,
          unrealized_pnl = (shares * $2) - (shares * avg_cost),
          last_updated = CURRENT_TIMESTAMP
        WHERE symbol = $1 AND status = 'active'
      `;

      const result = await pool.query(query, [update.symbol, update.currentPrice]);
      updatedCount += result.rowCount;
    }

    logger.info('Portfolio prices updated', {
      updatedCount,
      symbolsUpdated: priceUpdates.length,
    });

    return updatedCount;
  } catch (error) {
    logger.error('Error updating portfolio prices', {
      error: error.message,
    });
    throw error;
  }
};

/**
 * Get portfolio summary
 * @param {string} userId - User UUID
 * @returns {Promise<Object>} Portfolio summary
 */
export const getPortfolioSummary = async (userId) => {
  try {
    const query = `
      SELECT
        COUNT(*) as position_count,
        SUM(total_value) as total_value,
        SUM(unrealized_pnl) as total_pnl,
        AVG(CASE WHEN unrealized_pnl > 0 THEN unrealized_pnl END) as avg_profit,
        AVG(CASE WHEN unrealized_pnl < 0 THEN unrealized_pnl END) as avg_loss
      FROM portfolios
      WHERE user_id = $1 AND status = 'active'
    `;

    const result = await pool.query(query, [userId]);
    const row = result.rows[0];

    return {
      positionCount: parseInt(row.position_count) || 0,
      totalValue: parseFloat(row.total_value) || 0,
      totalPnL: parseFloat(row.total_pnl) || 0,
      avgProfit: parseFloat(row.avg_profit) || 0,
      avgLoss: parseFloat(row.avg_loss) || 0,
    };
  } catch (error) {
    logger.error('Error getting portfolio summary', {
      error: error.message,
      userId,
    });
    throw error;
  }
};

export default {
  getUserPortfolios,
  getPortfolioById,
  getPortfolioBySymbol,
  createPortfolio,
  updatePortfolio,
  deletePortfolio,
  updatePortfolioPrices,
  getPortfolioSummary,
};
