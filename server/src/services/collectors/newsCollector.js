/**
 * News Events Collector
 * Fetches financial news from NewsAPI and other sources
 */

import BaseCollector from './baseCollector.js';

class NewsCollector extends BaseCollector {
  constructor(config = {}) {
    super('NewsAPI', {
      sourceType: 'news',
      apiKey: config.apiKey || process.env.NEWS_API_KEY || '',
      baseUrl: 'https://newsapi.org/v2',
      ...config,
    });

    // Keywords to search for
    this.keywords = [
      'stock market',
      'earnings',
      'IPO',
      'merger',
      'acquisition',
      'Fed',
      'inflation',
      'recession',
      'cryptocurrency',
      'bitcoin',
      'ethereum',
    ];
  }

  /**
   * Collect news events
   * @returns {Promise<Object>} Collection result
   */
  async collect() {
    const startTime = Date.now();

    try {
      logger.info('Starting news collection');

      let successCount = 0;
      let errorCount = 0;

      // Fetch business news
      try {
        const businessNews = await this.fetchBusinessNews();
        await this.saveNewsEvents(businessNews);
        successCount += businessNews.length;
      } catch (error) {
        logger.error('Failed to fetch business news', {
          error: error.message,
        });
        errorCount++;
      }

      // Fetch crypto news
      try {
        const cryptoNews = await this.fetchCryptoNews();
        await this.saveNewsEvents(cryptoNews);
        successCount += cryptoNews.length;
      } catch (error) {
        logger.error('Failed to fetch crypto news', {
          error: error.message,
        });
        errorCount++;
      }

      // Fetch tech news
      try {
        const techNews = await this.fetchTechNews();
        await this.saveNewsEvents(techNews);
        successCount += techNews.length;
      } catch (error) {
        logger.error('Failed to fetch tech news', {
          error: error.message,
        });
        errorCount++;
      }

      await this.recordSuccess(successCount);

      logger.info('News collection completed', {
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
   * Fetch business news
   * @returns {Promise<Array>} Array of news articles
   */
  async fetchBusinessNews() {
    try {
      const url = `${this.config.baseUrl}/everything?q=business OR finance OR stock-market&language=en&sortBy=publishedAt&apiKey=${this.config.apiKey}`;

      const response = await this.fetchWithRetry(async () => {
        const res = await fetch(url);
        if (!res.ok) {
          throw new Error(`HTTP ${res.status}: ${res.statusText}`);
        }
        return res.json();
      });

      if (response.status === 'error') {
        throw new Error(response.message);
      }

      const articles = response.articles || [];

      return this.normalizeNewsArticles(articles, 'business');
    } catch (error) {
      logger.error('Failed to fetch business news', {
        error: error.message,
      });
      return [];
    }
  }

  /**
   * Fetch cryptocurrency news
   * @returns {Promise<Array>} Array of news articles
   */
  async fetchCryptoNews() {
    try {
      const url = `${this.config.baseUrl}/everything?q=cryptocurrency OR bitcoin OR ethereum&language=en&sortBy=publishedAt&apiKey=${this.config.apiKey}`;

      const response = await this.fetchWithRetry(async () => {
        const res = await fetch(url);
        if (!res.ok) {
          throw new Error(`HTTP ${res.status}: ${res.statusText}`);
        }
        return res.json();
      });

      if (response.status === 'error') {
        throw new Error(response.message);
      }

      const articles = response.articles || [];

      return this.normalizeNewsArticles(articles, 'crypto');
    } catch (error) {
      logger.error('Failed to fetch crypto news', {
        error: error.message,
      });
      return [];
    }
  }

  /**
   * Fetch tech news
   * @returns {Promise<Array>} Array of news articles
   */
  async fetchTechNews() {
    try {
      const url = `${this.config.baseUrl}/everything?q=technology&language=en&sortBy=publishedAt&apiKey=${this.config.apiKey}`;

      const response = await this.fetchWithRetry(async () => {
        const res = await fetch(url);
        if (!res.ok) {
          throw new Error(`HTTP ${res.status}: ${res.statusText}`);
        }
        return res.json();
      });

      if (response.status === 'error') {
        throw new Error(response.message);
      }

      const articles = response.articles || [];

      return this.normalizeNewsArticles(articles, 'technology');
    } catch (error) {
      logger.error('Failed to fetch tech news', {
        error: error.message,
      });
      return [];
    }
  }

  /**
   * Normalize news articles to standard format
   * @param {Array} articles - Raw articles from API
   * @param {string} category - News category
   * @returns {Array} Normalized articles
   */
  normalizeNewsArticles(articles, category) {
    return articles
      .filter((article) => article.title && article.title !== '[Removed]')
      .map((article) => ({
        title: article.title,
        description: article.description,
        source: article.source?.name || 'Unknown',
        url: article.url,
        category: this.categorizeArticle(article.title, category),
        importanceScore: this.calculateImportance(article),
        publishedAt: article.publishedAt ? new Date(article.publishedAt) : new Date(),
      }));
  }

  /**
   * Categorize article
   * @param {string} title - Article title
   * @param {string} defaultCategory - Default category
   * @returns {string} Category
   */
  categorizeArticle(title, defaultCategory) {
    const lowerTitle = title.toLowerCase();

    if (lowerTitle.includes('earnings') || lowerTitle.includes('quarterly')) {
      return 'earnings';
    }
    if (lowerTitle.includes('merger') || lowerTitle.includes('acquisition')) {
      return 'merger';
    }
    if (lowerTitle.includes('launch') || lowerTitle.includes('product')) {
      return 'product';
    }
    if (lowerTitle.includes('sec') || lowerTitle.includes('regulation')) {
      return 'regulation';
    }
    if (lowerTitle.includes('fed') || lowerTitle.includes('inflation') || lowerTitle.includes('interest rate')) {
      return 'macro';
    }

    return defaultCategory;
  }

  /**
   * Calculate importance score (0-100)
   * @param {Object} article - Article object
   * @returns {number} Importance score
   */
  calculateImportance(article) {
    let score = 50; // Base score

    const title = article.title?.toLowerCase() || '';
    const description = article.description?.toLowerCase() || '';

    // Increase score for important keywords
    const importantKeywords = [
      'breaking',
      'urgent',
      'major',
      'significant',
      'surge',
      'plunge',
      'beat',
      'miss',
      'upgrade',
      'downgrade',
      'bankruptcy',
      'ipo',
    ];

    for (const keyword of importantKeywords) {
      if (title.includes(keyword)) {
        score += 10;
      }
    }

    // Increase score for certain categories
    if (title.includes('earnings')) {
      score += 20;
    }
    if (title.includes('merger') || title.includes('acquisition')) {
      score += 25;
    }
    if (title.includes('fed') || title.includes('interest rate')) {
      score += 15;
    }

    // Decrease score for minor news
    const minorKeywords = ['update', 'summary', 'weekly', 'daily recap'];
    for (const keyword of minorKeywords) {
      if (title.includes(keyword)) {
        score -= 10;
      }
    }

    return Math.max(0, Math.min(100, score));
  }

  /**
   * Extract symbols from article text
   * @param {string} text - Text to search
   * @returns {Array<string>} Array of symbols
   */
  extractSymbols(text) {
    if (!text) {
      return [];
    }

    // Common stock mentions (simplified)
    const symbols = [];

    // Check for common ticker patterns (e.g., $AAPL, AAPL stock)
    const tickerPattern = /\$([A-Z]{1,5})\b|([A-Z]{1,5})\s+stock/gi;
    const matches = text.match(tickerPattern);

    if (matches) {
      for (const match of matches) {
        const symbol = match.replace(/\$| stock/gi, '').toUpperCase();
        if (symbol.length >= 2 && symbol.length <= 5) {
          symbols.push(symbol);
        }
      }
    }

    return [...new Set(symbols)]; // Remove duplicates
  }

  /**
   * Save news events to database
   * @param {Array} articles - Articles to save
   */
  async saveNewsEvents(articles) {
    try {
      const { default: db } = await import('../../config/database.js');

      let savedCount = 0;

      for (const article of articles) {
        try {
          const query = `
            INSERT INTO news_events (
              title, description, source, url, category,
              importance_score, published_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7)
            ON CONFLICT (url) DO NOTHING
          `;

          await db.pool.query(query, [
            article.title,
            article.description,
            article.source,
            article.url,
            article.category,
            article.importanceScore,
            article.publishedAt,
          ]);

          savedCount++;
        } catch (error) {
          logger.error('Failed to save news event', {
            error: error.message,
            title: article.title,
          });
        }
      }

      logger.info(`Saved ${savedCount} news events`);

      return savedCount;
    } catch (error) {
      logger.error('Failed to save news events', {
        error: error.message,
      });
      throw error;
    }
  }

  /**
   * Get tracked symbols from user portfolios/watchlists
   * @returns {Promise<Array<string>>} Array of symbols
   */
  async getTrackedSymbols() {
    try {
      const { default: db } = await import('../../config/database.js');

      const query = `
        SELECT DISTINCT symbol
        FROM (
          SELECT symbol FROM portfolios WHERE status = 'active' AND asset_type IN ('stock', 'etf')
          UNION
          SELECT symbol FROM watchlists WHERE asset_type IN ('stock', 'etf')
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
}

export default NewsCollector;
