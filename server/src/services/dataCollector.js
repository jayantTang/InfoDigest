/**
 * Data Collector Service for v2.0
 * Coordinates data collection from multiple sources
 */

import logger from '../config/logger.js';
import { pool } from '../config/database.js';

class DataCollector {
  constructor() {
    this.collectors = new Map();
    this.isCollecting = false;
  }

  /**
   * Register a data collector
   * @param {string} name - Collector name
   * @param {Object} collector - Collector instance with collect() method
   */
  registerCollector(name, collector) {
    this.collectors.set(name, collector);
    logger.info('Data collector registered', { name });
  }

  /**
   * Unregister a data collector
   * @param {string} name - Collector name
   */
  unregisterCollector(name) {
    this.collectors.delete(name);
    logger.info('Data collector unregistered', { name });
  }

  /**
   * Run all registered collectors
   * @returns {Promise<Object>} Collection results
   */
  async collectAll() {
    if (this.isCollecting) {
      logger.warn('Collection already in progress, skipping');
      return {
        status: 'skipped',
        message: 'Collection already in progress',
      };
    }

    this.isCollecting = true;
    const startTime = Date.now();
    const results = {
      timestamp: new Date().toISOString(),
      collectors: {},
      summary: {
        total: 0,
        successful: 0,
        failed: 0,
        skipped: 0,
      },
    };

    logger.info('Starting data collection cycle', {
      collectorsCount: this.collectors.size,
    });

    // Run all collectors in parallel
    const collectionPromises = Array.from(this.collectors.entries()).map(
      async ([name, collector]) => {
        const collectorStart = Date.now();

        try {
          logger.info(`Collector started: ${name}`);
          const result = await collector.collect();
          const duration = Date.now() - collectorStart;

          logger.info(`Collector completed: ${name}`, {
            duration,
            records: result.recordsCollected || 0,
          });

          return {
            name,
            status: 'success',
            duration,
            result,
          };
        } catch (error) {
          const duration = Date.now() - collectorStart;

          logger.error(`Collector failed: ${name}`, {
            error: error.message,
            duration,
          });

          // Update data source status in database
          await this.updateDataSourceStatus(name, false, error.message);

          return {
            name,
            status: 'error',
            duration,
            error: error.message,
          };
        }
      }
    );

    const collectorResults = await Promise.all(collectionPromises);

    // Process results
    for (const result of collectorResults) {
      results.collectors[result.name] = result;
      results.summary.total++;

      if (result.status === 'success') {
        results.summary.successful++;
      } else if (result.status === 'error') {
        results.summary.failed++;
      } else {
        results.summary.skipped++;
      }
    }

    const totalDuration = Date.now() - startTime;

    logger.info('Data collection cycle completed', {
      totalDuration,
      summary: results.summary,
    });

    this.isCollecting = false;

    return {
      status: 'completed',
      duration: totalDuration,
      ...results,
    };
  }

  /**
   * Run a specific collector
   * @param {string} name - Collector name
   * @returns {Promise<Object>} Collection result
   */
  async collectOne(name) {
    const collector = this.collectors.get(name);

    if (!collector) {
      throw new Error(`Collector not found: ${name}`);
    }

    logger.info(`Running single collector: ${name}`);
    const startTime = Date.now();

    try {
      const result = await collector.collect();
      const duration = Date.now() - startTime;

      logger.info(`Collector completed: ${name}`, { duration });

      return {
        name,
        status: 'success',
        duration,
        result,
      };
    } catch (error) {
      const duration = Date.now() - startTime;

      logger.error(`Collector failed: ${name}`, {
        error: error.message,
        duration,
      });

      await this.updateDataSourceStatus(name, false, error.message);

      return {
        name,
        status: 'error',
        duration,
        error: error.message,
      };
    }
  }

  /**
   * Update data source status in database
   * @param {string} sourceName - Source name
   * @param {boolean} isActive - Whether source is active
   * @param {string} error - Error message if any
   */
  async updateDataSourceStatus(sourceName, isActive, error = null) {
    try {
      const query = `
        UPDATE data_source_status
        SET
          is_active = $2,
          last_fetch_at = CURRENT_TIMESTAMP,
          last_error = $3,
          error_count = CASE
            WHEN $3 IS NOT NULL THEN error_count + 1
            ELSE 0
          END,
          updated_at = CURRENT_TIMESTAMP
        WHERE source_name = $1
      `;

      await pool.query(query, [sourceName, isActive, error]);
    } catch (err) {
      logger.error('Failed to update data source status', {
        error: err.message,
        sourceName,
      });
    }
  }

  /**
   * Get status of all collectors
   * @returns {Promise<Object>} Collector status
   */
  async getStatus() {
    const status = {
      isCollecting: this.isCollecting,
      registeredCollectors: Array.from(this.collectors.keys()),
      timestamp: new Date().toISOString(),
    };

    return status;
  }
}

// Singleton instance
const dataCollector = new DataCollector();

export default dataCollector;
