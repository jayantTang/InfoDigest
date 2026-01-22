import { pool } from '../config/database.js';
import logger from '../config/logger.js';

/**
 * Historical Price Change Calculator
 * Calculates price changes for different time periods
 */
class PriceChangeCalculator {
  /**
   * Get price from N days ago
   * @param {string} symbol - Stock/index symbol
   * @param {number} daysAgo - Number of days to look back
   * @returns {Promise<number|null>} Price or null if not found
   */
  async getPriceAt(symbol, daysAgo) {
    // Input validation to prevent SQL injection
    if (!symbol || typeof symbol !== 'string') {
      throw new Error('Symbol must be a non-empty string');
    }
    if (!Number.isInteger(daysAgo) || daysAgo < 1 || daysAgo > 10000) {
      throw new Error('daysAgo must be a positive integer');
    }

    try {
      const query = `
        SELECT close_price
        FROM prices
        WHERE symbol = $1
          AND timestamp >= NOW() - INTERVAL '${daysAgo} days'
          AND is_estimated = false
        ORDER BY timestamp ASC
        LIMIT 1
      `;

      const result = await pool.query(query, [symbol]);

      if (result.rows.length === 0) {
        return null;
      }

      return parseFloat(result.rows[0].close_price);
    } catch (error) {
      logger.error('Failed to get historical price', {
        symbol,
        daysAgo,
        error: error.message,
      });
      return null;
    }
  }

  /**
   * Get latest price for a symbol
   * @param {string} symbol - Stock/index symbol
   * @returns {Promise<number>} Latest price
   */
  async getLatestPrice(symbol) {
    try {
      const query = `
        SELECT close_price
        FROM prices
        WHERE symbol = $1
        ORDER BY timestamp DESC
        LIMIT 1
      `;

      const result = await pool.query(query, [symbol]);

      if (result.rows.length === 0) {
        throw new Error(`No price data found for ${symbol}`);
      }

      return parseFloat(result.rows[0].close_price);
    } catch (error) {
      logger.error('Failed to get latest price', {
        symbol,
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Calculate price changes for all time periods
   * @param {string} symbol - Stock/index symbol
   * @returns {Promise<Object>} Price changes for each period
   */
  async calculatePriceChange(symbol) {
    try {
      const periods = {
        '1d': 1,
        '1w': 7,
        '1m': 30,
        '3m': 90,
        '1y': 365,
        '3y': 1095,
      };

      const currentPrice = await this.getLatestPrice(symbol);
      const changes = {};

      for (const [period, days] of Object.entries(periods)) {
        const pastPrice = await this.getPriceAt(symbol, days);

        if (pastPrice && pastPrice > 0) {
          const changePercent = ((currentPrice - pastPrice) / pastPrice) * 100;
          changes[period] = {
            value: `${changePercent >= 0 ? '+' : ''}${changePercent.toFixed(1)}`,
            available: true,
          };
        } else {
          changes[period] = {
            available: false,
          };
        }
      }

      logger.info('Calculated price changes', {
        symbol,
        currentPrice,
        periods: Object.keys(changes).length,
      });

      return changes;
    } catch (error) {
      logger.error('Failed to calculate price changes', {
        symbol,
        error: error.message,
      });
      throw error;
    }
  }
}

export default new PriceChangeCalculator();
