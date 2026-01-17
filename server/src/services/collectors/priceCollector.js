/**
 * Price Data Collector
 * Fetches stock and ETF prices from Alpha Vantage
 */

import BaseCollector from './baseCollector.js';

class PriceCollector extends BaseCollector {
  constructor(config = {}) {
    super('Alpha Vantage', {
      sourceType: 'price',
      apiKey: config.apiKey || process.env.STOCK_API_KEY || '',
      baseUrl: 'https://www.alphavantage.co/query',
      ...config,
    });
  }

  /**
   * Collect price data for all tracked symbols
   * @returns {Promise<Object>} Collection result
   */
  async collect() {
    const startTime = Date.now();

    try {
      logger.info('Starting price data collection');

      // Get all unique symbols from portfolios and watchlists
      const symbols = await this.getTrackedSymbols();

      if (symbols.length === 0) {
        logger.info('No symbols to fetch prices for');
        return {
          recordsCollected: 0,
          duration: Date.now() - startTime,
        };
      }

      logger.info(`Fetching prices for ${symbols.length} symbols`);

      let successCount = 0;
      let errorCount = 0;

      // Fetch prices in batches to respect rate limits
      const batchSize = 5; // Alpha Vantage free tier: 5 calls/minute

      for (let i = 0; i < symbols.length; i += batchSize) {
        const batch = symbols.slice(i, i + batchSize);

        for (const symbol of batch) {
          try {
            await this.fetchAndSavePrice(symbol);
            successCount++;

            // Rate limiting: wait 12 seconds between calls (free tier limit)
            if (i + batch.indexOf(symbol) < symbols.length - 1) {
              await this.sleep(12000);
            }
          } catch (error) {
            logger.error(`Failed to fetch price for ${symbol}`, {
              error: error.message,
            });
            errorCount++;
          }
        }
      }

      await this.recordSuccess(successCount);

      logger.info('Price data collection completed', {
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
   * Get all unique symbols from portfolios and watchlists
   * @returns {Promise<Array<string>>} Array of symbols
   */
  async getTrackedSymbols() {
    try {
      const query = `
        SELECT DISTINCT symbol
        FROM (
          SELECT symbol FROM portfolios WHERE status = 'active'
          UNION
          SELECT symbol FROM watchlists
        ) AS symbols
        ORDER BY symbol
      `;

      const result = await this.pool?.query(query);

      if (!result) {
        // Fallback if pool not available
        return ['SPY', 'QQQ', 'DIA']; // Default ETFs
      }

      return result.rows.map((row) => row.symbol);
    } catch (error) {
      logger.error('Failed to get tracked symbols', {
        error: error.message,
      });
      return ['SPY', 'QQQ', 'DIA']; // Default ETFs
    }
  }

  /**
   * Fetch price for a single symbol and save to database
   * @param {string} symbol - Stock symbol
   */
  async fetchAndSavePrice(symbol) {
    try {
      const url = `${this.config.baseUrl}?function=GLOBAL_QUOTE&symbol=${symbol}&apikey=${this.config.apiKey}`;

      const response = await this.fetchWithRetry(async () => {
        const res = await fetch(url);
        if (!res.ok) {
          throw new Error(`HTTP ${res.status}: ${res.statusText}`);
        }
        return res.json();
      });

      // Check for API error messages
      if (response['Error Message']) {
        throw new Error(response['Error Message']);
      }

      if (response['Note']) {
        throw new Error('API call frequency limit exceeded');
      }

      const quote = response['Global Quote'];

      if (!quote) {
        throw new Error('Invalid response format');
      }

      // Parse price data
      const priceData = {
        symbol: quote['01. symbol'],
        openPrice: this.safeParseFloat(quote['02. open']),
        highPrice: this.safeParseFloat(quote['03. high']),
        lowPrice: this.safeParseFloat(quote['04. low']),
        closePrice: this.safeParseFloat(quote['05. price']),
        volume: this.safeParseInt(quote['06. volume'], 0),
        timestamp: new Date(quote['07. latest trading day']),
      };

      await this.savePriceData(priceData);

      logger.debug(`Price saved for ${symbol}`, {
        price: priceData.closePrice,
      });
    } catch (error) {
      logger.error(`Failed to fetch/save price for ${symbol}`, {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Save price data to database
   * @param {Object} priceData - Price data
   */
  async savePriceData(priceData) {
    try {
      const { default: db } = await import('../../config/database.js');

      const query = `
        INSERT INTO prices (
          symbol, open_price, high_price, low_price, close_price,
          volume, timestamp, is_estimated
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, false)
        ON CONFLICT DO NOTHING
      `;

      await db.pool.query(query, [
        priceData.symbol,
        priceData.openPrice,
        priceData.highPrice,
        priceData.lowPrice,
        priceData.closePrice,
        priceData.volume,
        priceData.timestamp,
      ]);
    } catch (error) {
      logger.error('Failed to save price data', {
        error: error.message,
        symbol: priceData.symbol,
      });
      throw error;
    }
  }

  /**
   * Fetch historical prices for a symbol
   * @param {string} symbol - Stock symbol
   * @param {string} timeframe - Timeframe (daily, weekly, monthly)
   * @returns {Promise<Array>} Array of price data
   */
  async fetchHistoricalPrices(symbol, timeframe = 'daily') {
    try {
      const functionMap = {
        daily: 'TIME_SERIES_DAILY',
        weekly: 'TIME_SERIES_WEEKLY',
        monthly: 'TIME_SERIES_MONTHLY',
      };

      const fn = functionMap[timeframe] || 'TIME_SERIES_DAILY';

      const url = `${this.config.baseUrl}?function=${fn}&symbol=${symbol}&apikey=${this.config.apiKey}&outputsize=compact`;

      const response = await this.fetchWithRetry(async () => {
        const res = await fetch(url);
        if (!res.ok) {
          throw new Error(`HTTP ${res.status}: ${res.statusText}`);
        }
        return res.json();
      });

      if (response['Error Message']) {
        throw new Error(response['Error Message']);
      }

      const timeSeriesKey = `Time Series (${timeframe.charAt(0).toUpperCase() + timeframe.slice(1)})`;
      const timeSeries = response[timeSeriesKey];

      if (!timeSeries) {
        throw new Error('Invalid response format');
      }

      const prices = Object.entries(timeSeries).map(([date, data]) => ({
        symbol,
        timestamp: new Date(date),
        openPrice: this.safeParseFloat(data['1. open']),
        highPrice: this.safeParseFloat(data['2. high']),
        lowPrice: this.safeParseFloat(data['3. low']),
        closePrice: this.safeParseFloat(data['4. close']),
        volume: this.safeParseInt(data['5. volume'], 0),
      }));

      return prices;
    } catch (error) {
      logger.error(`Failed to fetch historical prices for ${symbol}`, {
        error: error.message,
      });
      throw error;
    }
  }
}

export default PriceCollector;
