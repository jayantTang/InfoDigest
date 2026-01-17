/**
 * Macro Economic Data Collector
 * Fetches macro economic indicators from FRED (Federal Reserve Economic Data)
 */

import BaseCollector from './baseCollector.js';

class MacroCollector extends BaseCollector {
  constructor(config = {}) {
    super('FRED', {
      sourceType: 'macro',
      apiKey: config.apiKey || process.env.FRED_API_KEY || '',
      baseUrl: 'https://api.stlouisfed.org/fred',
      ...config,
    });

    // Key indicators to track
    this.indicators = [
      { code: 'GDP', name: 'Gross Domestic Product', frequency: 'quarterly' },
      { code: 'CPIAUCSL', name: 'Consumer Price Index', frequency: 'monthly' },
      { code: 'UNRATE', name: 'Unemployment Rate', frequency: 'monthly' },
      { code: 'FEDFUNDS', name: 'Federal Funds Rate', frequency: 'monthly' },
      { code: 'DGS10', name: '10-Year Treasury Constant Maturity Rate', frequency: 'daily' },
      { code: 'DGS2', name: '2-Year Treasury Constant Maturity Rate', frequency: 'daily' },
      { code: 'PAYEMS', name: 'All Employees, Nonfarm', frequency: 'monthly' },
      { code: 'UMCSENT', name: 'Consumer Sentiment', frequency: 'monthly' },
    ];
  }

  /**
   * Collect macro economic data
   * @returns {Promise<Object>} Collection result
   */
  async collect() {
    const startTime = Date.now();

    try {
      logger.info('Starting macro economic data collection');

      if (!this.config.apiKey) {
        logger.warn('FRED API key not configured, skipping macro data collection');
        return {
          recordsCollected: 0,
          duration: Date.now() - startTime,
          message: 'API key not configured',
        };
      }

      let successCount = 0;
      let errorCount = 0;

      for (const indicator of this.indicators) {
        try {
          await this.fetchIndicator(indicator);
          successCount++;

          // Rate limiting: FRED allows 120 requests per minute
          await this.sleep(500);
        } catch (error) {
          logger.error(`Failed to fetch indicator ${indicator.code}`, {
            error: error.message,
          });
          errorCount++;
        }
      }

      await this.recordSuccess(successCount);

      logger.info('Macro data collection completed', {
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
   * Fetch data for a specific indicator
   * @param {Object} indicator - Indicator config
   */
  async fetchIndicator(indicator) {
    try {
      const url = `${this.config.baseUrl}/series/observations?series_id=${indicator.code}&api_key=${this.config.apiKey}&file_type=json&limit=1`;

      const response = await this.fetchWithRetry(async () => {
        const res = await fetch(url);
        if (!res.ok) {
          throw new Error(`HTTP ${res.status}: ${res.statusText}`);
        }
        return res.json();
      });

      if (response.error_code) {
        throw new Error(response.error_message);
      }

      const observations = response.observations;

      if (!observations || observations.length === 0) {
        logger.warn(`No observations for ${indicator.code}`);
        return;
      }

      // Get the most recent observation
      const latest = observations[0];

      await this.saveIndicator({
        indicatorCode: indicator.code,
        indicatorName: indicator.name,
        country: 'US',
        value: parseFloat(latest.value),
        unit: this.getIndicatorUnit(indicator.code),
        period: latest.date,
        releasedAt: latest.realtime_start ? new Date(latest.realtime_start) : new Date(),
        source: 'FRED',
      });

      logger.debug(`Saved indicator ${indicator.code}: ${latest.value}`);
    } catch (error) {
      logger.error(`Failed to fetch indicator ${indicator.code}`, {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Get unit for indicator
   * @param {string} code - Indicator code
   * @returns {string} Unit
   */
  getIndicatorUnit(code) {
    const units = {
      'GDP': 'billion dollars',
      'CPIAUCSL': 'index',
      'UNRATE': 'percent',
      'FEDFUNDS': 'percent',
      'DGS10': 'percent',
      'DGS2': 'percent',
      'PAYEMS': 'thousands',
      'UMCSENT': 'index',
    };

    return units[code] || 'unknown';
  }

  /**
   * Save indicator to database
   * @param {Object} data - Indicator data
   */
  async saveIndicator(data) {
    try {
      const { default: db } = await import('../../config/database.js');

      const query = `
        INSERT INTO macro_data (
          indicator_code, indicator_name, country,
          value, unit, period, released_at, source
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        ON CONFLICT (indicator_code, period)
        DO UPDATE SET
          value = EXCLUDED.value,
          released_at = EXCLUDED.released_at
      `;

      await db.pool.query(query, [
        data.indicatorCode,
        data.indicatorName,
        data.country,
        data.value,
        data.unit,
        data.period,
        data.releasedAt,
        data.source,
      ]);

      logger.debug(`Saved macro indicator ${data.indicatorCode}`);
    } catch (error) {
      logger.error('Failed to save macro indicator', {
        error: error.message,
        indicatorCode: data.indicatorCode,
      });
      throw error;
    }
  }

  /**
   * Get latest macro data summary
   * @returns {Promise<Object>} Macro data summary
   */
  async getMacroSummary() {
    try {
      const { default: db } = await import('../../config/database.js');

      const query = `
        SELECT DISTINCT ON (indicator_code)
          indicator_code,
          indicator_name,
          value,
          unit,
          period,
          released_at
        FROM macro_data
        ORDER BY indicator_code, period DESC
      `;

      const result = await db.pool.query(query);

      const summary = {};

      for (const row of result.rows) {
        summary[row.indicator_code] = {
          name: row.indicator_name,
          value: row.value,
          unit: row.unit,
          period: row.period,
          releasedAt: row.released_at,
        };
      }

      return summary;
    } catch (error) {
      logger.error('Failed to get macro summary', {
        error: error.message,
      });
      return {};
    }
  }

  /**
   * Get GDP growth rate
   * @returns {Promise<number>} GDP growth rate (percent)
   */
  async getGDPGrowthRate() {
    try {
      const { default: db } = await import('../../config/database.js');

      const query = `
        SELECT value, period
        FROM macro_data
        WHERE indicator_code = 'GDP'
        ORDER BY period DESC
        LIMIT 2
      `;

      const result = await db.pool.query(query);

      if (result.rows.length < 2) {
        return null;
      }

      const current = result.rows[0].value;
      const previous = result.rows[1].value;

      if (!current || !previous) {
        return null;
      }

      return ((current - previous) / previous) * 100;
    } catch (error) {
      logger.error('Failed to calculate GDP growth rate', {
        error: error.message,
      });
      return null;
    }
  }
}

export default MacroCollector;
