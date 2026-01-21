/**
 * Economic Index Collector
 * Fetches A-stock indices, US ETFs, commodities, and forex data
 * Uses Yahoo Finance for A-shares, commodities, and forex
 * Uses Alpha Vantage for US ETFs (already configured)
 */

import BaseCollector from './baseCollector.js';
import yahooFinance from 'yahoo-finance2';
import { pool } from '../../config/database.js';
import logger from '../../config/logger.js';

class IndexCollector extends BaseCollector {
  constructor(config = {}) {
    super('Index Collector', {
      sourceType: 'index',
      apiKey: config.apiKey || process.env.STOCK_API_KEY || '',
      ...config,
    });

    // Define indices to collect
    this.indices = {
      // A股指数 (Yahoo Finance)
      aStock: [
        { symbol: '000001.SS', name: '上证指数', market: 'CN' },
        { symbol: '000300.SS', name: '沪深300', market: 'CN' },
        { symbol: '399006.SZ', name: '创业板指', market: 'CN' },
      ],
      // 美股ETF (Alpha Vantage)
      usEtf: [
        { symbol: 'SPY', name: '标普500', market: 'US' },
        { symbol: 'QQQ', name: '纳斯达克100', market: 'US' },
        { symbol: 'DIA', name: '道琼斯', market: 'US' },
      ],
      // 商品 (Yahoo Finance)
      commodities: [
        { symbol: 'GC=F', name: '黄金', market: 'COMEX' },
        { symbol: 'CL=F', name: '石油', market: 'NYMEX' },
      ],
      // 美元指数 (Yahoo Finance)
      forex: [
        { symbol: 'DX-Y.NYB', name: '美元指数', market: 'US' },
      ],
    };
  }

  /**
   * Collect all index data
   * @returns {Promise<Object>} Collection result
   */
  async collect() {
    const startTime = Date.now();
    let successCount = 0;
    let errorCount = 0;

    try {
      logger.info('Starting index data collection');

      // 1. Collect A股指数 (Yahoo Finance)
      logger.info('Fetching A-stock indices from Yahoo Finance');
      for (const index of this.indices.aStock) {
        try {
          await this.fetchFromYahoo(index);
          successCount++;
          // Yahoo Finance has no rate limit, but be gentle
          await this.sleep(500);
        } catch (error) {
          logger.error(`Failed to fetch A-stock index ${index.symbol}`, {
            error: error.message,
          });
          errorCount++;
        }
      }

      // 2. Collect 美股ETF (Alpha Vantage)
      logger.info('Fetching US ETFs from Alpha Vantage');
      for (const index of this.indices.usEtf) {
        try {
          await this.fetchFromAlphaVantage(index);
          successCount++;
          // Alpha Vantage free tier: 5 calls/minute
          // Wait 12 seconds between calls
          await this.sleep(12000);
        } catch (error) {
          logger.error(`Failed to fetch US ETF ${index.symbol}`, {
            error: error.message,
          });
          errorCount++;
        }
      }

      // 3. Collect commodities (Yahoo Finance)
      logger.info('Fetching commodities from Yahoo Finance');
      for (const commodity of this.indices.commodities) {
        try {
          await this.fetchFromYahoo(commodity);
          successCount++;
          await this.sleep(500);
        } catch (error) {
          logger.error(`Failed to fetch commodity ${commodity.symbol}`, {
            error: error.message,
          });
          errorCount++;
        }
      }

      // 4. Collect 美元指数 (Yahoo Finance)
      logger.info('Fetching USD index from Yahoo Finance');
      try {
        await this.fetchFromYahoo(this.indices.forex[0]);
        successCount++;
      } catch (error) {
        logger.error('Failed to fetch USD index', {
          error: error.message,
        });
        errorCount++;
      }

      await this.recordSuccess(successCount);

      logger.info('Index data collection completed', {
        recordsCollected: successCount,
        errors: errorCount,
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
   * Fetch index data from Yahoo Finance
   * @param {Object} index - Index config object
   */
  async fetchFromYahoo(index) {
    try {
      logger.debug(`Fetching ${index.symbol} from Yahoo Finance`);

      const quote = await yahooFinance.quote(index.symbol, {
        fields: ['regularMarketPrice', 'regularMarketTime', 'regularMarketChange', 'regularMarketChangePercent'],
      });

      // Yahoo Finance returns price in regularMarketPrice
      const price = quote.regularMarketPrice;
      const timestamp = new Date(quote.regularMarketTime * 1000);

      if (price === null || price === undefined) {
        throw new Error(`No price data available for ${index.symbol}`);
      }

      // Save to database
      await this.savePriceData({
        symbol: index.symbol,
        name: index.name,
        market: index.market,
        openPrice: price,
        highPrice: price,
        lowPrice: price,
        closePrice: price,
        volume: 0, // Indices don't have volume
        timestamp: timestamp,
      });

      logger.debug(`Successfully fetched ${index.symbol} from Yahoo Finance`, {
        price: price,
        timestamp: timestamp.toISOString(),
      });
    } catch (error) {
      logger.error(`Yahoo Finance fetch failed for ${index.symbol}`, {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Fetch index data from Alpha Vantage
   * Reuses logic from PriceCollector
   * @param {Object} index - Index config object
   */
  async fetchFromAlphaVantage(index) {
    try {
      logger.debug(`Fetching ${index.symbol} from Alpha Vantage`);

      const url = `${this.config.baseUrl}?function=GLOBAL_QUOTE&symbol=${index.symbol}&apikey=${this.config.apiKey}`;

      const response = await fetchWithRetry(() => fetch(url));
      const data = await response.json();

      if (data['Global Quote'] && data['Global Quote']['01. symbol']) {
        const quote = data['Global Quote'];

        const price = this.safeParseFloat(quote['05. price']);
        const change = this.safeParseFloat(quote['09. change']);
        const changePercent = this.safeParseFloat(quote['10. change percent']);
        const timestamp = new Date();

        if (price === null) {
          throw new Error(`Invalid price data for ${index.symbol}`);
        }

        // Save to database
        await this.savePriceData({
          symbol: index.symbol,
          name: index.name,
          market: index.market,
          openPrice: price,
          highPrice: price,
          lowPrice: price,
          closePrice: price,
          volume: 0,
          timestamp: timestamp,
        });

        logger.debug(`Successfully fetched ${index.symbol} from Alpha Vantage`, {
          price: price,
          change: change,
          changePercent: changePercent,
        });
      } else {
        throw new Error(`Invalid response format for ${index.symbol}`);
      }
    } catch (error) {
      logger.error(`Alpha Vantage fetch failed for ${index.symbol}`, {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Save price data to database
   * @param {Object} data - Price data object
   */
  async savePriceData(data) {
    try {
      const query = `
        INSERT INTO prices (
          symbol, open_price, high_price, low_price, close_price,
          volume, timestamp, is_estimated
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, false)
        ON CONFLICT DO NOTHING
      `;

      await pool.query(query, [
        data.symbol,
        data.openPrice,
        data.highPrice,
        data.lowPrice,
        data.closePrice,
        data.volume || 0,
        data.timestamp,
      ]);

      logger.debug(`Saved price data for ${data.symbol}`, {
        price: data.closePrice,
        timestamp: data.timestamp,
      });
    } catch (error) {
      logger.error(`Failed to save price data for ${data.symbol}`, {
        error: error.message,
      });
      throw error;
    }
  }
}

export default IndexCollector;
