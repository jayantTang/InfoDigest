/**
 * Sina Finance Collector
 * Fallback data source for A-stock indices when Yahoo Finance fails
 * Uses Sina Finance public API (free, no API key required)
 */

import BaseCollector from './baseCollector.js';
import { pool } from '../../config/database.js';
import logger from '../../config/logger.js';

class SinaCollector extends BaseCollector {
  constructor() {
    super('Sina Finance', {
      sourceType: 'index',
    });

    // Symbol mapping: Yahoo Finance symbol -> Sina Finance symbol
    this.symbolMap = {
      '000001.SS': 'sh000001',  // 上证指数
      '000300.SS': 'sh000300',  // 沪深300
      '399006.SZ': 'sz399006',  // 创业板指
    };

    // Name mapping for display
    this.nameMap = {
      'sh000001': '上证指数',
      'sh000300': '沪深300',
      'sz399006': '创业板指',
    };
  }

  /**
   * Fetch index data from Sina Finance
   * @param {string} yahooSymbol - Yahoo Finance symbol format
   * @returns {Promise<Object>} Index data object
   */
  async fetchIndex(yahooSymbol) {
    const sinaSymbol = this.symbolMap[yahooSymbol];
    if (!sinaSymbol) {
      throw new Error(`Symbol ${yahooSymbol} not supported by Sina Finance`);
    }

    try {
      logger.debug(`Fetching ${yahooSymbol} from Sina Finance as ${sinaSymbol}`);

      // Sina Finance API endpoint
      const url = `https://hq.sinajs.cn/list=${sinaSymbol}`;

      const response = await this.fetchWithRetry(async () => {
        const res = await fetch(url, {
          headers: {
            'Referer': 'https://finance.sina.com.cn',
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          },
        });
        if (!res.ok) {
          throw new Error(`HTTP ${res.status}: ${res.statusText}`);
        }
        return res.text();
      });

      // Parse response data
      // Format: var hq_str_sh000001="上证指数,3234.56,3238.12,3220.45,3236.78,3238.12,3240.00,..."
      const match = response.match(/="([^"]+)"/);
      if (!match) {
        throw new Error(`Invalid response format for ${sinaSymbol}`);
      }

      const parts = match[1].split(',');
      const name = this.nameMap[sinaSymbol] || parts[0];
      const price = parseFloat(parts[1]);
      const openPrice = parseFloat(parts[2]) || price;
      const highPrice = parseFloat(parts[3]) || price;
      const lowPrice = parseFloat(parts[4]) || price;

      if (isNaN(price) || price === 0) {
        throw new Error(`Invalid price data for ${yahooSymbol}: ${parts[1]}`);
      }

      const data = {
        symbol: yahooSymbol,
        name: name,
        market: 'CN',
        openPrice: openPrice,
        highPrice: highPrice,
        lowPrice: lowPrice,
        closePrice: price,
        volume: 0, // Sina doesn't provide volume in this endpoint
        timestamp: new Date(),
      };

      logger.debug(`Successfully fetched ${yahooSymbol} from Sina Finance`, {
        price: price,
        name: name,
      });

      return data;
    } catch (error) {
      logger.error(`Sina Finance fetch failed for ${yahooSymbol}`, {
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

      logger.debug(`Saved price data for ${data.symbol} from Sina Finance`, {
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

  /**
   * Check if a symbol is supported
   * @param {string} yahooSymbol - Yahoo Finance symbol
   * @returns {boolean}
   */
  isSupported(yahooSymbol) {
    return yahooSymbol in this.symbolMap;
  }
}

export default SinaCollector;
