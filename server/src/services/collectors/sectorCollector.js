/**
 * Sector Performance Aggregator
 * Aggregates sector performance data from ETFs and individual stocks
 */

import BaseCollector from './baseCollector.js';

class SectorCollector extends BaseCollector {
  constructor(config = {}) {
    super('SectorAggregator', {
      sourceType: 'aggregated',
      ...config,
    });

    // Sector ETFs
    this.sectorETFs = {
      '科技': 'XLK',
      '半导体': 'SOXX',
      '金融': 'XLF',
      '能源': 'XLE',
      '医疗': 'XLV',
      '消费': 'XLY',
      '公用事业': 'XLU',
      '房地产': 'XLRE',
      '材料': 'XLB',
      '工业': 'XLI',
    };
  }

  /**
   * Aggregate sector performance data
   * @returns {Promise<Object>} Collection result
   */
  async collect() {
    const startTime = Date.now();

    try {
      logger.info('Starting sector data aggregation');

      let successCount = 0;
      let errorCount = 0;

      // Get all sectors
      const sectors = await this.getAllSectors();

      for (const sector of sectors) {
        try {
          await this.aggregateSectorPerformance(sector);
          successCount++;
        } catch (error) {
          logger.error(`Failed to aggregate data for sector ${sector.name}`, {
            error: error.message,
          });
          errorCount++;
        }
      }

      await this.recordSuccess(successCount);

      logger.info('Sector aggregation completed', {
        successCount,
        errorCount,
        duration: Date.now() - startTime,
      });

      return {
        recordsCollected: successCount,
        errors: errorCount,
        duration: Date.now() - startTime,
      };
    } catch (error) {
      await this.recordFailure(error);
      throw error;
    }
  }

  /**
   * Get all sectors from database
   * @returns {Promise<Array>} Array of sectors
   */
  async getAllSectors() {
    try {
      const { default: db } = await import('../../config/database.js');

      const query = 'SELECT * FROM sectors ORDER BY name';

      const result = await db.pool.query(query);

      return result.rows;
    } catch (error) {
      logger.error('Failed to get sectors', {
        error: error.message,
      });
      return [];
    }
  }

  /**
   * Aggregate performance for a sector
   * @param {Object} sector - Sector object
   */
  async aggregateSectorPerformance(sector) {
    try {
      const today = new Date().toISOString().split('T')[0];

      // Get sector ETF price if available
      let etfReturn = null;
      if (sector.etf_symbol) {
        etfReturn = await this.getETFReturn(sector.etf_symbol);
      }

      // Get individual stock performance in this sector
      const stockPerformance = await this.getSectorStockPerformance(sector.name);

      // Calculate aggregate metrics
      const avgReturn = this.calculateAverageReturn(stockPerformance);
      const advancingCount = stockPerformance.filter((s) => s.changePercent > 0).length;
      const decliningCount = stockPerformance.filter((s) => s.changePercent < 0).length;

      // Get top performers and laggards
      const leaders = stockPerformance
        .filter((s) => s.changePercent > 0)
        .sort((a, b) => b.changePercent - a.changePercent)
        .slice(0, 5);

      const laggards = stockPerformance
        .filter((s) => s.changePercent < 0)
        .sort((a, b) => a.changePercent - b.changePercent)
        .slice(0, 5);

      // Save sector performance
      await this.saveSectorPerformance({
        sectorId: sector.id,
        date: today,
        returnPercent: etfReturn || avgReturn,
        avgPE: null, // Would need fundamental data
        pePercentile: null,
        netInflow: null, // Would need flow data
        institutionalInflow: null,
        leaders: leaders.map((l) => ({
          symbol: l.symbol,
          changePercent: l.changePercent,
        })),
        laggards: laggards.map((l) => ({
          symbol: l.symbol,
          changePercent: l.changePercent,
        })),
        advancingCount,
        decliningCount,
      });

      logger.debug(`Aggregated performance for ${sector.name}`);
    } catch (error) {
      logger.error(`Failed to aggregate performance for ${sector.name}`, {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Get ETF return for today
   * @param {string} etfSymbol - ETF symbol
   * @returns {Promise<number|null>} Return percentage
   */
  async getETFReturn(etfSymbol) {
    try {
      const { default: db } = await import('../../config/database.js');

      const query = `
        SELECT close_price, timestamp
        FROM prices
        WHERE symbol = $1
        ORDER BY timestamp DESC
        LIMIT 2
      `;

      const result = await db.pool.query(query, [etfSymbol]);

      if (result.rows.length < 2) {
        return null;
      }

      const currentPrice = result.rows[0].close_price;
      const previousPrice = result.rows[1].close_price;

      if (!currentPrice || !previousPrice) {
        return null;
      }

      return ((currentPrice - previousPrice) / previousPrice) * 100;
    } catch (error) {
      logger.error(`Failed to get ETF return for ${etfSymbol}`, {
        error: error.message,
      });
      return null;
    }
  }

  /**
   * Get stock performance for a sector
   * @param {string} sectorName - Sector name
   * @returns {Promise<Array>} Array of stock performance
   */
  async getSectorStockPerformance(sectorName) {
    try {
      const { default: db } = await import('../../config/database.js');

      const query = `
        SELECT DISTINCT
          a.symbol,
          p.close_price,
          LAG(p.close_price) OVER (PARTITION BY a.symbol ORDER BY p.timestamp) as prev_close
        FROM assets a
        JOIN prices p ON a.symbol = p.symbol
        WHERE a.sector = $1
          AND p.timestamp >= CURRENT_DATE - INTERVAL '7 days'
        ORDER BY a.symbol, p.timestamp DESC
      `;

      const result = await db.pool.query(query, [sectorName]);

      // Group by symbol and get latest vs previous
      const stockMap = new Map();

      for (const row of result.rows) {
        if (!stockMap.has(row.symbol)) {
          const currentPrice = row.close_price;
          const previousPrice = row.prev_close;

          if (currentPrice && previousPrice) {
            const changePercent = ((currentPrice - previousPrice) / previousPrice) * 100;
            stockMap.set(row.symbol, {
              symbol: row.symbol,
              changePercent,
            });
          }
        }
      }

      return Array.from(stockMap.values());
    } catch (error) {
      logger.error(`Failed to get stock performance for ${sectorName}`, {
        error: error.message,
      });
      return [];
    }
  }

  /**
   * Calculate average return
   * @param {Array} performances - Array of performance data
   * @returns {number} Average return
   */
  calculateAverageReturn(performances) {
    if (performances.length === 0) {
      return 0;
    }

    const sum = performances.reduce((acc, p) => acc + p.changePercent, 0);
    return sum / performances.length;
  }

  /**
   * Save sector performance to database
   * @param {Object} performance - Performance data
   */
  async saveSectorPerformance(performance) {
    try {
      const { default: db } = await import('../../config/database.js');

      const query = `
        INSERT INTO sector_performance (
          sector_id, date, return_percent,
          net_inflow, institutional_inflow,
          leaders, laggards,
          advancing_count, declining_count
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        ON CONFLICT (sector_id, date) DO UPDATE SET
          return_percent = EXCLUDED.return_percent,
          leaders = EXCLUDED.leaders,
          laggards = EXCLUDED.laggards,
          advancing_count = EXCLUDED.advancing_count,
          declining_count = EXCLUDED.declining_count
      `;

      await db.pool.query(query, [
        performance.sectorId,
        performance.date,
        performance.returnPercent,
        performance.netInflow,
        performance.institutionalInflow,
        JSON.stringify(performance.leaders),
        JSON.stringify(performance.laggards),
        performance.advancingCount,
        performance.decliningCount,
      ]);

      logger.debug(`Saved sector performance for sector ${performance.sectorId}`);
    } catch (error) {
      logger.error('Failed to save sector performance', {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Get sector performance summary
   * @param {number} days - Number of days to look back
   * @returns {Promise<Array>} Array of sector summaries
   */
  async getSectorSummary(days = 7) {
    try {
      const { default: db } = await import('../../config/database.js');

      const query = `
        SELECT
          s.name,
          s.name_en,
          s.etf_symbol,
          AVG(sp.return_percent) as avg_return,
          STDDEV(sp.return_percent) as volatility
        FROM sectors s
        LEFT JOIN sector_performance sp ON s.id = sp.sector_id
        WHERE sp.date >= CURRENT_DATE - INTERVAL '${days} days'
        GROUP BY s.id, s.name, s.name_en, s.etf_symbol
        ORDER BY avg_return DESC NULLS LAST
      `;

      const result = await db.pool.query(query);

      return result.rows;
    } catch (error) {
      logger.error('Failed to get sector summary', {
        error: error.message,
      });
      return [];
    }
  }
}

export default SectorCollector;
