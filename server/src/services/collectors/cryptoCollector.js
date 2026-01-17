/**
 * Cryptocurrency Data Collector
 * Fetches crypto prices and market data from CoinGecko
 */

import BaseCollector from './baseCollector.js';

class CryptoCollector extends BaseCollector {
  constructor(config = {}) {
    super('CoinGecko', {
      sourceType: 'crypto_price',
      apiKey: config.apiKey || process.env.COINGECKO_API_KEY || '',
      baseUrl: 'https://api.coingecko.com/api/v3',
      ...config,
    });

    // Top cryptocurrencies to track (by market cap)
    this.topCryptoIds = [
      'bitcoin',
      'ethereum',
      'binancecoin',
      'ripple',
      'cardano',
      'solana',
      'polkadot',
      'dogecoin',
      'avalanche-2',
      'chainlink',
    ];
  }

  /**
   * Collect cryptocurrency data
   * @returns {Promise<Object>} Collection result
   */
  async collect() {
    const startTime = Date.now();

    try {
      logger.info('Starting cryptocurrency data collection');

      let successCount = 0;
      let errorCount = 0;

      // Fetch market data for top cryptocurrencies
      try {
        await this.fetchMarketData();
        successCount++;
      } catch (error) {
        logger.error('Failed to fetch crypto market data', {
          error: error.message,
        });
        errorCount++;
      }

      // Save price data to prices table
      try {
        const pricesSaved = await this.saveCryptoPrices();
        successCount += pricesSaved;
      } catch (error) {
        logger.error('Failed to save crypto prices', {
          error: error.message,
        });
        errorCount++;
      }

      await this.recordSuccess(successCount);

      logger.info('Cryptocurrency data collection completed', {
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
   * Fetch market data from CoinGecko
   * @returns {Promise<Object>} Market data
   */
  async fetchMarketData() {
    try {
      const url = `${this.config.baseUrl}/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1&sparkline=false&price_change_percentage=1h,24h,7d`;

      const response = await this.fetchWithRetry(async () => {
        const headers = {};
        if (this.config.apiKey) {
          headers['x-cg-demo-api-key'] = this.config.apiKey;
        }

        const res = await fetch(url, { headers });
        if (!res.ok) {
          throw new Error(`HTTP ${res.status}: ${res.statusText}`);
        }
        return res.json();
      });

      if (!Array.isArray(response)) {
        throw new Error('Invalid response format');
      }

      // Update crypto assets and save market data
      for (const coin of response) {
        await this.updateCryptoAsset(coin);
      }

      logger.info(`Updated ${response.length} crypto assets`);

      return response;
    } catch (error) {
      logger.error('Failed to fetch crypto market data', {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Update or create crypto asset in database
   * @param {Object} coin - Coin data from CoinGecko
   */
  async updateCryptoAsset(coin) {
    try {
      const { default: db } = await import('../../config/database.js');

      const query = `
        INSERT INTO crypto_assets (
          symbol, name, crypto_sector, market_cap_rank,
          circulating_supply, total_supply, max_supply,
          website, twitter
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        ON CONFLICT (symbol)
        DO UPDATE SET
          name = EXCLUDED.name,
          crypto_sector = EXCLUDED.crypto_sector,
          market_cap_rank = EXCLUDED.market_cap_rank,
          circulating_supply = EXCLUDED.circulating_supply,
          total_supply = EXCLUDED.total_supply,
          max_supply = EXCLUDED.max_supply,
          updated_at = CURRENT_TIMESTAMP
      `;

      await db.pool.query(query, [
        coin.symbol.toUpperCase(),
        coin.name,
        this.mapCryptoSector(coin.categories),
        coin.market_cap_rank,
        this.safeParseFloat(coin.circulating_supply),
        this.safeParseFloat(coin.total_supply),
        this.safeParseFloat(coin.max_supply),
        coin.links?.homepage?.[0] || null,
        coin.links?.twitter_screen_name || null,
      ]);

      // Cache current price for later
      this.currentPrices = this.currentPrices || {};
      this.currentPrices[coin.symbol.toUpperCase()] = {
        price: this.safeParseFloat(coin.current_price),
        marketCap: this.safeParseFloat(coin.market_cap),
        volume24h: this.safeParseFloat(coin.total_volume),
        change24h: this.safeParseFloat(coin.price_change_percentage_24h),
      };
    } catch (error) {
      logger.error(`Failed to update crypto asset ${coin.symbol}`, {
        error: error.message,
      });
    }
  }

  /**
   * Map CoinGecko categories to our crypto sectors
   * @param {Array<string>} categories - CoinGecko categories
   * @returns {string} Crypto sector
   */
  mapCryptoSector(categories) {
    if (!categories || !Array.isArray(categories)) {
      return 'other';
    }

    const categoryMap = {
      'layer-1': 'layer1',
      'layer-2': 'layer2',
      'decentralized-exchange': 'defi',
      'defi': 'defi',
      'meme': 'meme',
      'stablecoin': 'stablecoin',
      'exchange': 'exchange',
      'artificial-intelligence': 'ai',
    };

    for (const category of categories) {
      const lowerCategory = category.toLowerCase();
      for (const [key, value] of Object.entries(categoryMap)) {
        if (lowerCategory.includes(key)) {
          return value;
        }
      }
    }

    return 'other';
  }

  /**
   * Save crypto prices to prices table
   * @returns {Promise<number>} Number of prices saved
   */
  async saveCryptoPrices() {
    try {
      const { default: db } = await import('../../config/database.js');

      if (!this.currentPrices || Object.keys(this.currentPrices).length === 0) {
        return 0;
      }

      let savedCount = 0;

      for (const [symbol, data] of Object.entries(this.currentPrices)) {
        const query = `
          INSERT INTO prices (symbol, close_price, volume, timestamp, is_estimated)
          VALUES ($1, $2, $3, CURRENT_TIMESTAMP, true)
          ON CONFLICT DO NOTHING
        `;

        await db.pool.query(query, [
          symbol,
          data.price,
          data.volume24h || 0,
        ]);

        savedCount++;
      }

      logger.info(`Saved ${savedCount} crypto prices`);

      return savedCount;
    } catch (error) {
      logger.error('Failed to save crypto prices', {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Fetch on-chain metrics for a cryptocurrency
   * @param {string} symbol - Crypto symbol
   * @returns {Promise<Object>} On-chain metrics
   */
  async fetchOnChainMetrics(symbol) {
    try {
      // This would typically use a specialized API like Etherscan, Whale Alert, etc.
      // For now, return a placeholder
      logger.warn(`On-chain metrics not yet implemented for ${symbol}`);

      return {
        symbol,
        timestamp: new Date(),
        metrics: {},
      };
    } catch (error) {
      logger.error(`Failed to fetch on-chain metrics for ${symbol}`, {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Fetch crypto market sentiment
   * @returns {Promise<Object>} Market sentiment data
   */
  async fetchMarketSentiment() {
    try {
      // CoinGecko has a fear/greed index endpoint
      const url = 'https://api.coingecko.com/api/v3/global';

      const response = await this.fetchWithRetry(async () => {
        const res = await fetch(url);
        if (!res.ok) {
          throw new Error(`HTTP ${res.status}: ${res.statusText}`);
        }
        return res.json();
      });

      const data = response.data;

      // Save sentiment data
      const { default: db } = await import('../../config/database.js');

      const topCryptos = Object.keys(data.market_cap_percentage).slice(0, 5);

      for (const symbol of topCryptos) {
        const query = `
          INSERT INTO crypto_sentiment (
            symbol, fear_greed, measured_at
          ) VALUES ($1, $2, CURRENT_TIMESTAMP)
          ON CONFLICT DO NOTHING
        `;

        await db.pool.query(query, [
          symbol.toUpperCase(),
          this.calculateFearGreed(data.market_cap_change_percentage_24h),
        ]);
      }

      logger.info('Crypto sentiment data saved');

      return data;
    } catch (error) {
      logger.error('Failed to fetch crypto sentiment', {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Calculate fear/greed index from market data
   * @param {number} changePercentage - 24h change percentage
   * @returns {number} Fear/greed score (0-100)
   */
  calculateFearGreed(changePercentage) {
    // Simple calculation: higher positive change = higher greed
    // Normalize -10% to +10% range to 0-100
    const normalized = (parseFloat(changePercentage) + 10) / 20 * 100;
    return Math.max(0, Math.min(100, Math.round(normalized)));
  }

  /**
   * Get list of crypto IDs from user portfolios/watchlists
   * @returns {Promise<Array<string>>} Array of crypto symbols
   */
  async getTrackedCryptos() {
    try {
      const { default: db } = await import('../../config/database.js');

      const query = `
        SELECT DISTINCT symbol
        FROM (
          SELECT symbol FROM portfolios WHERE asset_type = 'crypto' AND status = 'active'
          UNION
          SELECT symbol FROM watchlists WHERE asset_type = 'crypto'
        ) AS symbols
      `;

      const result = await db.pool.query(query);

      return result.rows.map((row) => row.symbol.toLowerCase());
    } catch (error) {
      logger.error('Failed to get tracked cryptos', {
        error: error.message,
      });
      return this.topCryptoIds;
    }
  }
}

export default CryptoCollector;
