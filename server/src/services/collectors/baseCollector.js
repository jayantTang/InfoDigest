/**
 * Base Data Collector Class
 * All data collectors should extend this class
 */

import logger from '../../config/logger.js';
import { pool } from '../../config/database.js';

export class BaseCollector {
  constructor(name, config = {}) {
    this.name = name;
    this.config = config;
    this.lastFetch = null;
    this.recordsCollected = 0;
  }

  /**
   * Collect data - must be implemented by subclasses
   * @returns {Promise<Object>} Collection result
   */
  async collect() {
    throw new Error('collect() must be implemented by subclass');
  }

  /**
   * Initialize the collector
   * @returns {Promise<void>}
   */
  async initialize() {
    logger.info(`Initializing collector: ${this.name}`);
    // Subclasses can override this
  }

  /**
   * Health check for the collector
   * @returns {Promise<boolean>} True if healthy
   */
  async healthCheck() {
    try {
      // Check if data source status exists and is active
      const query = `
        SELECT is_active, error_count
        FROM data_source_status
        WHERE source_name = $1
      `;

      const result = await pool.query(query, [this.name]);

      if (result.rows.length === 0) {
        // Create status record
        await this.createDataSourceStatus();
        return true;
      }

      const status = result.rows[0];
      return status.is_active && status.error_count < 10;
    } catch (error) {
      logger.error(`Health check failed for ${this.name}`, {
        error: error.message,
      });
      return false;
    }
  }

  /**
   * Create data source status record
   */
  async createDataSourceStatus() {
    try {
      const query = `
        INSERT INTO data_source_status (source_name, source_type, is_active, config)
        VALUES ($1, $2, true, $3)
        ON CONFLICT (source_name) DO NOTHING
      `;

      await pool.query(query, [
        this.name,
        this.config.sourceType || 'unknown',
        JSON.stringify(this.config),
      ]);

      logger.info(`Data source status created for ${this.name}`);
    } catch (error) {
      logger.error(`Failed to create data source status for ${this.name}`, {
        error: error.message,
      });
    }
  }

  /**
   * Update last fetch time
   */
  async updateLastFetch() {
    try {
      const query = `
        UPDATE data_source_status
        SET last_fetch_at = CURRENT_TIMESTAMP
        WHERE source_name = $1
      `;

      await pool.query(query, [this.name]);
      this.lastFetch = new Date();
    } catch (error) {
      logger.error(`Failed to update last fetch time for ${this.name}`, {
        error: error.message,
      });
    }
  }

  /**
   * Record successful fetch
   * @param {number} count - Number of records collected
   */
  async recordSuccess(count = 0) {
    try {
      const query = `
        UPDATE data_source_status
        SET
          last_fetch_at = CURRENT_TIMESTAMP,
          error_count = 0,
          updated_at = CURRENT_TIMESTAMP
        WHERE source_name = $1
      `;

      await pool.query(query, [this.name]);
      this.lastFetch = new Date();
      this.recordsCollected = count;

      logger.info(`${this.name} fetch successful`, {
        recordsCollected: count,
      });
    } catch (error) {
      logger.error(`Failed to record success for ${this.name}`, {
        error: error.message,
      });
    }
  }

  /**
   * Record failed fetch
   * @param {Error} error - Error object
   */
  async recordFailure(error) {
    try {
      const query = `
        UPDATE data_source_status
        SET
          last_error = $2,
          error_count = error_count + 1,
          updated_at = CURRENT_TIMESTAMP
        WHERE source_name = $1
      `;

      await pool.query(query, [this.name, error.message]);

      logger.error(`${this.name} fetch failed`, {
        error: error.message,
      });
    } catch (err) {
      logger.error(`Failed to record failure for ${this.name}`, {
        error: err.message,
      });
    }
  }

  /**
   * Sleep utility for rate limiting
   * @param {number} ms - Milliseconds to sleep
   */
  async sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  /**
   * Fetch with retry logic
   * @param {Function} fetchFn - Fetch function
   * @param {number} maxRetries - Maximum retry attempts
   * @param {number} retryDelay - Delay between retries
   */
  async fetchWithRetry(fetchFn, maxRetries = 3, retryDelay = 1000) {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await fetchFn();
      } catch (error) {
        if (attempt === maxRetries) {
          throw error;
        }

        logger.warn(`${this.name} fetch attempt ${attempt} failed, retrying...`, {
          error: error.message,
          attempt,
          maxRetries,
        });

        await this.sleep(retryDelay * attempt);
      }
    }
  }

  /**
   * Safe parseFloat
   * @param {*} value - Value to parse
   * @param {number} defaultValue - Default value if parsing fails
   */
  safeParseFloat(value, defaultValue = null) {
    if (value === null || value === undefined || value === '') {
      return defaultValue;
    }

    const parsed = parseFloat(value);
    return isNaN(parsed) ? defaultValue : parsed;
  }

  /**
   * Safe parseInt
   * @param {*} value - Value to parse
   * @param {number} defaultValue - Default value if parsing fails
   */
  safeParseInt(value, defaultValue = null) {
    if (value === null || value === undefined || value === '') {
      return defaultValue;
    }

    const parsed = parseInt(value);
    return isNaN(parsed) ? defaultValue : parsed;
  }
}

export default BaseCollector;
