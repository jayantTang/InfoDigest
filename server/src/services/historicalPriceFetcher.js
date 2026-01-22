/**
 * Historical Price Fetcher Service
 * Fetches historical price data from Alpha Vantage API
 * Used for lazy-loading historical data when needed for calculations
 */

import axios from 'axios';
import logger from '../config/logger.js';
import { pool } from '../config/database.js';
import config from '../config/index.js';

class HistoricalPriceFetcher {
  constructor() {
    this.baseUrl = 'https://www.alphavantage.co/query';
    this.apiKey = config.apiKeys.alphaVantage;
    this.cache = new Map(); // Simple in-memory cache for API responses
  }

  /**
   * Fetch historical price for a symbol on a specific date using Alpha Vantage
   * @param {string} symbol - Stock/index symbol (e.g., 'SPY', '000001.SS')
   * @param {Date} targetDate - Target date to fetch
   * @returns {Promise<number|null>} Close price or null if not found
   */
  async fetchHistoricalPrice(symbol, targetDate) {
    try {
      logger.info('Fetching historical price from Alpha Vantage', {
        symbol,
        targetDate: targetDate.toISOString().split('T')[0],
      });

      // Check cache first (Alpha Vantage has rate limits: 5 calls/minute for free tier)
      const cacheKey = `${symbol}_${targetDate.toISOString().split('T')[0]}`;
      if (this.cache.has(cacheKey)) {
        logger.debug('Returning cached historical price', { cacheKey });
        return this.cache.get(cacheKey);
      }

      // Use TIME_SERIES_DAILY to get daily data
      const response = await axios.get(this.baseUrl, {
        params: {
          function: 'TIME_SERIES_DAILY',
          symbol: symbol,
          outputsize: 'full',
          apikey: this.apiKey,
        },
        timeout: 10000,
      });

      const timeSeries = response.data['Time Series (Daily)'];

      if (!timeSeries) {
        const errorMessage = response.data['Note'] || response.data['Error Message'] || 'Unknown error';
        logger.warn('Alpha Vantage API error', { symbol, error: errorMessage });
        return null;
      }

      // Find the closest trading day to target date
      const targetDateStr = targetDate.toISOString().split('T')[0]; // YYYY-MM-DD
      let closestDate = null;
      let minDiff = Infinity;
      let price = null;

      // Search in a window around the target date
      for (let offset = 0; offset <= 7; offset++) {
        const searchDate = new Date(targetDate);
        searchDate.setDate(searchDate.getDate() - offset);
        const dateStr = searchDate.toISOString().split('T')[0];

        if (timeSeries[dateStr]) {
          price = parseFloat(timeSeries[dateStr]['4. close']);
          closestDate = dateStr;
          break;
        }

        // Also check forward (for future dates)
        const futureDate = new Date(targetDate);
        futureDate.setDate(futureDate.getDate() + offset);
        const futureDateStr = futureDate.toISOString().split('T')[0];

        if (timeSeries[futureDateStr]) {
          price = parseFloat(timeSeries[futureDateStr]['4. close']);
          closestDate = futureDateStr;
          break;
        }
      }

      if (price === null) {
        logger.warn('No valid price data found for date range', {
          symbol,
          targetDate: targetDateStr,
        });
        return null;
      }

      const actualDate = new Date(closestDate);

      logger.info('Successfully fetched historical price', {
        symbol,
        targetDate: targetDateStr,
        actualDate: closestDate,
        price,
      });

      // Save to database for future use
      await this.saveHistoricalPrice(symbol, price, actualDate);

      // Cache the result
      this.cache.set(cacheKey, price);

      return price;
    } catch (error) {
      logger.error('Failed to fetch historical price from Alpha Vantage', {
        symbol,
        targetDate: targetDate.toISOString().split('T')[0],
        error: error.message,
      });
      return null;
    }
  }

  /**
   * Save historical price to database
   * @param {string} symbol - Stock/index symbol
   * @param {number} price - Close price
   * @param {Date} date - Date of the price
   */
  async saveHistoricalPrice(symbol, price, date) {
    try {
      // Check if already exists
      const checkQuery = `
        SELECT id FROM prices
        WHERE symbol = $1
          AND DATE(timestamp) = DATE($2)
        LIMIT 1
      `;
      const checkResult = await pool.query(checkQuery, [symbol, date]);

      if (checkResult.rows.length > 0) {
        logger.debug('Historical price already exists, skipping insert', {
          symbol,
          date: date.toISOString().split('T')[0],
        });
        return; // Already exists, don't insert duplicate
      }

      // Insert new historical price
      const insertQuery = `
        INSERT INTO prices (symbol, close_price, timestamp, is_estimated, created_at)
        VALUES ($1, $2, $3, false, CURRENT_TIMESTAMP)
        ON CONFLICT DO NOTHING
      `;
      await pool.query(insertQuery, [symbol, price, date]);

      logger.info('Saved historical price to database', {
        symbol,
        date: date.toISOString().split('T')[0],
        price,
      });
    } catch (error) {
      logger.error('Failed to save historical price to database', {
        symbol,
        date: date.toISOString().split('T')[0],
        error: error.message,
      });
      // Don't throw - we still want to return the price even if save fails
    }
  }

  /**
   * Fetch multiple historical prices in batch
   * @param {Array} requests - Array of {symbol, date} objects
   * @returns {Promise<Map>} Map of symbol-date to price
   */
  async fetchBatch(requests) {
    const results = new Map();

    logger.info('Fetching historical prices in batch', { count: requests.length });

    for (const { symbol, date } of requests) {
      try {
        const price = await this.fetchHistoricalPrice(symbol, date);
        const key = `${symbol}-${date.toISOString().split('T')[0]}`;
        results.set(key, price);

        // Small delay to avoid rate limiting
        await this.delay(200);
      } catch (error) {
        logger.error('Failed to fetch price in batch', {
          symbol,
          date: date.toISOString().split('T')[0],
          error: error.message,
        });
      }
    }

    return results;
  }

  /**
   * Delay helper
   * @param {number} ms - Milliseconds to delay
   * @returns {Promise<void>}
   */
  delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}

export default new HistoricalPriceFetcher();
