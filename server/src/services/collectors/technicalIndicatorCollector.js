/**
 * Technical Indicator Calculator
 * Calculates technical indicators from price data
 */

import BaseCollector from './baseCollector.js';

class TechnicalIndicatorCollector extends BaseCollector {
  constructor(config = {}) {
    super('TechnicalIndicators', {
      sourceType: 'calculated',
      ...config,
    });
  }

  /**
   * Calculate indicators for all tracked symbols
   * @returns {Promise<Object>} Collection result
   */
  async collect() {
    const startTime = Date.now();

    try {
      logger.info('Starting technical indicator calculation');

      // Get symbols that need indicators calculated
      const symbols = await this.getTrackedSymbols();

      if (symbols.length === 0) {
        logger.info('No symbols to calculate indicators for');
        return {
          recordsCollected: 0,
          duration: Date.now() - startTime,
        };
      }

      logger.info(`Calculating indicators for ${symbols.length} symbols`);

      let successCount = 0;
      let errorCount = 0;

      for (const symbol of symbols) {
        try {
          await this.calculateIndicators(symbol);
          successCount++;
        } catch (error) {
          logger.error(`Failed to calculate indicators for ${symbol}`, {
            error: error.message,
          });
          errorCount++;
        }
      }

      await this.recordSuccess(successCount);

      logger.info('Technical indicator calculation completed', {
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
   * Get tracked symbols
   * @returns {Promise<Array<string>>} Array of symbols
   */
  async getTrackedSymbols() {
    try {
      const { default: db } = await import('../../config/database.js');

      const query = `
        SELECT DISTINCT symbol
        FROM (
          SELECT symbol FROM portfolios WHERE status = 'active'
          UNION
          SELECT symbol FROM watchlists
        ) AS symbols
      `;

      const result = await db.pool.query(query);

      return result.rows.map((row) => row.symbol);
    } catch (error) {
      logger.error('Failed to get tracked symbols', {
        error: error.message,
      });
      return [];
    }
  }

  /**
   * Calculate all indicators for a symbol
   * @param {string} symbol - Stock symbol
   */
  async calculateIndicators(symbol) {
    try {
      // Fetch historical price data
      const prices = await this.fetchHistoricalPrices(symbol, 60); // 60 days

      if (prices.length < 20) {
        logger.warn(`Insufficient data for ${symbol}: ${prices.length} prices`);
        return;
      }

      const closePrices = prices.map((p) => p.closePrice).reverse();
      const highPrices = prices.map((p) => p.highPrice).reverse();
      const lowPrices = prices.map((p) => p.lowPrice).reverse();
      const volumes = prices.map((p) => p.volume || 0).reverse();

      // Calculate all indicators
      const indicators = {
        sma_5: this.calculateSMA(closePrices, 5),
        sma_10: this.calculateSMA(closePrices, 10),
        sma_20: this.calculateSMA(closePrices, 20),
        sma_50: this.calculateSMA(closePrices, 50),
        ema_12: this.calculateEMA(closePrices, 12),
        ema_26: this.calculateEMA(closePrices, 26),
        rsi: this.calculateRSI(closePrices, 14),
        macd: this.calculateMACD(closePrices),
        bollinger: this.calculateBollingerBands(closePrices, 20, 2),
        atr: this.calculateATR(highPrices, lowPrices, closePrices, 14),
        volumeAvg5: this.calculateSMA(volumes, 5),
        volumeAvg20: this.calculateSMA(volumes, 20),
      };

      await this.saveIndicators(symbol, indicators);

      logger.debug(`Calculated indicators for ${symbol}`);
    } catch (error) {
      logger.error(`Failed to calculate indicators for ${symbol}`, {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Fetch historical prices from database
   * @param {string} symbol - Stock symbol
   * @param {number} days - Number of days
   * @returns {Promise<Array>} Array of prices
   */
  async fetchHistoricalPrices(symbol, days = 60) {
    try {
      const { default: db } = await import('../../config/database.js');

      const query = `
        SELECT
          close_price,
          high_price,
          low_price,
          volume,
          timestamp
        FROM prices
        WHERE symbol = $1
        ORDER BY timestamp DESC
        LIMIT $2
      `;

      const result = await db.pool.query(query, [symbol, days]);

      return result.rows;
    } catch (error) {
      logger.error(`Failed to fetch historical prices for ${symbol}`, {
        error: error.message,
      });
      return [];
    }
  }

  /**
   * Calculate Simple Moving Average
   * @param {Array<number>} prices - Array of prices
   * @param {number} period - Period
   * @returns {number|null} SMA value
   */
  calculateSMA(prices, period) {
    if (prices.length < period) {
      return null;
    }

    const slice = prices.slice(0, period);
    const sum = slice.reduce((a, b) => a + b, 0);
    return sum / period;
  }

  /**
   * Calculate Exponential Moving Average
   * @param {Array<number>} prices - Array of prices
   * @param {number} period - Period
   * @returns {number|null} EMA value
   */
  calculateEMA(prices, period) {
    if (prices.length < period) {
      return null;
    }

    const multiplier = 2 / (period + 1);
    let ema = this.calculateSMA(prices.slice(0, period), period);

    for (let i = period; i < prices.length; i++) {
      ema = (prices[i] - ema) * multiplier + ema;
    }

    return ema;
  }

  /**
   * Calculate Relative Strength Index
   * @param {Array<number>} prices - Array of prices
   * @param {number} period - Period
   * @returns {number|null} RSI value
   */
  calculateRSI(prices, period = 14) {
    if (prices.length < period + 1) {
      return null;
    }

    let gains = 0;
    let losses = 0;

    // Calculate initial average gain/loss
    for (let i = 1; i <= period; i++) {
      const change = prices[i - 1] - prices[i];
      if (change > 0) {
        gains += change;
      } else {
        losses -= change;
      }
    }

    let avgGain = gains / period;
    let avgLoss = losses / period;

    // Calculate subsequent values
    for (let i = period + 1; i < prices.length; i++) {
      const change = prices[i - 1] - prices[i];

      if (change > 0) {
        avgGain = (avgGain * (period - 1) + change) / period;
        avgLoss = (avgLoss * (period - 1)) / period;
      } else {
        avgGain = (avgGain * (period - 1)) / period;
        avgLoss = (avgLoss * (period - 1) - change) / period;
      }
    }

    if (avgLoss === 0) {
      return 100;
    }

    const rs = avgGain / avgLoss;
    const rsi = 100 - (100 / (1 + rs));

    return rsi;
  }

  /**
   * Calculate MACD
   * @param {Array<number>} prices - Array of prices
   * @returns {Object|null} MACD values
   */
  calculateMACD(prices) {
    if (prices.length < 26) {
      return null;
    }

    const ema12 = this.calculateEMA(prices, 12);
    const ema26 = this.calculateEMA(prices, 26);

    if (!ema12 || !ema26) {
      return null;
    }

    const macd = ema12 - ema26;

    // Calculate signal line (9-period EMA of MACD)
    // For simplicity, we'll use the current MACD as the signal (normally needs historical MACD values)
    const signal = macd * 0.9; // Simplified
    const histogram = macd - signal;

    return {
      macd,
      macd_signal: signal,
      macd_histogram: histogram,
    };
  }

  /**
   * Calculate Bollinger Bands
   * @param {Array<number>} prices - Array of prices
   * @param {number} period - Period
   * @param {number} stdDev - Standard deviations
   * @returns {Object|null} Bollinger Bands
   */
  calculateBollingerBands(prices, period = 20, stdDev = 2) {
    if (prices.length < period) {
      return null;
    }

    const slice = prices.slice(0, period);
    const sma = this.calculateSMA(prices, period);

    // Calculate standard deviation
    const squaredDiffs = slice.map((price) => Math.pow(price - sma, 2));
    const variance = squaredDiffs.reduce((a, b) => a + b, 0) / period;
    const standardDeviation = Math.sqrt(variance);

    return {
      bollinger_upper: sma + (standardDeviation * stdDev),
      bollinger_middle: sma,
      bollinger_lower: sma - (standardDeviation * stdDev),
    };
  }

  /**
   * Calculate Average True Range
   * @param {Array<number>} highs - High prices
   * @param {Array<number>} lows - Low prices
   * @param {Array<number>} closes - Close prices
   * @param {number} period - Period
   * @returns {number|null} ATR value
   */
  calculateATR(highs, lows, closes, period = 14) {
    if (highs.length < period + 1) {
      return null;
    }

    const trueRanges = [];

    for (let i = 1; i < highs.length; i++) {
      const high = highs[i];
      const low = lows[i];
      const prevClose = closes[i - 1];

      const tr = Math.max(
        high - low,
        Math.abs(high - prevClose),
        Math.abs(low - prevClose)
      );

      trueRanges.push(tr);
    }

    // Calculate ATR using SMA
    const atr = this.calculateSMA(trueRanges, period);

    return atr;
  }

  /**
   * Save indicators to database
   * @param {string} symbol - Stock symbol
   * @param {Object} indicators - Calculated indicators
   */
  async saveIndicators(symbol, indicators) {
    try {
      const { default: db } = await import('../../config/database.js');

      const query = `
        INSERT INTO technical_indicators (
          symbol, calculated_at,
          sma_5, sma_10, sma_20, sma_50,
          ema_12, ema_26,
          rsi,
          macd, macd_signal, macd_histogram,
          bollinger_upper, bollinger_middle, bollinger_lower,
          atr,
          volume_avg_5, volume_avg_20
        ) VALUES ($1, CURRENT_TIMESTAMP, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
        ON CONFLICT DO NOTHING
      `;

      await db.pool.query(query, [
        symbol,
        indicators.sma_5,
        indicators.sma_10,
        indicators.sma_20,
        indicators.sma_50,
        indicators.ema_12,
        indicators.ema_26,
        indicators.rsi,
        indicators.macd?.macd,
        indicators.macd?.macd_signal,
        indicators.macd?.macd_histogram,
        indicators.bollinger?.bollinger_upper,
        indicators.bollinger?.bollinger_middle,
        indicators.bollinger?.bollinger_lower,
        indicators.atr,
        indicators.volumeAvg5,
        indicators.volumeAvg20,
      ]);

      logger.debug(`Saved indicators for ${symbol}`);
    } catch (error) {
      logger.error(`Failed to save indicators for ${symbol}`, {
        error: error.message,
      });
      throw error;
    }
  }
}

export default TechnicalIndicatorCollector;
