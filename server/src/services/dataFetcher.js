import axios from 'axios';
import config from '../config/index.js';
import logger from '../config/logger.js';
import { query } from '../config/database.js';

/**
 * News Data Fetcher
 * Uses NewsAPI.org
 */
export class NewsFetcher {
  constructor() {
    this.apiKey = config.apiKeys.news;
    this.baseUrl = 'https://newsapi.org/v2';
  }

  async fetchTopHeadlines(country = 'us', pageSize = 20) {
    try {
      const response = await axios.get(`${this.baseUrl}/top-headlines`, {
        params: {
          country,
          pageSize,
          apiKey: this.apiKey,
        },
        timeout: 10000,
      });

      logger.info('Fetched news headlines', { count: response.data.articles?.length });

      return {
        source: 'NewsAPI',
        type: 'news',
        data: response.data.articles?.filter((article) => article.title?.toLowerCase() !== '[removed]') || [],
        fetchedAt: new Date().toISOString(),
      };
    } catch (error) {
      logger.error('NewsAPI fetch error', { error: error.message });
      throw new Error(`Failed to fetch news: ${error.message}`);
    }
  }

  async fetchTechNews() {
    try {
      const response = await axios.get(`${this.baseUrl}/everything`, {
        params: {
          q: 'technology OR AI OR artificial intelligence',
          language: 'en',
          sortBy: 'publishedAt',
          pageSize: 20,
          apiKey: this.apiKey,
        },
        timeout: 10000,
      });

      logger.info('Fetched tech news', { count: response.data.articles?.length });

      return {
        source: 'NewsAPI',
        type: 'news',
        category: 'technology',
        data: response.data.articles?.filter((article) => article.title?.toLowerCase() !== '[removed]') || [],
        fetchedAt: new Date().toISOString(),
      };
    } catch (error) {
      logger.error('Tech news fetch error', { error: error.message });
      throw new Error(`Failed to fetch tech news: ${error.message}`);
    }
  }
}

/**
 * Stock Data Fetcher
 * Uses Alpha Vantage API
 */
export class StockFetcher {
  constructor() {
    this.apiKey = config.apiKeys.stock;
    this.baseUrl = 'https://www.alphavantage.co/query';
  }

  async getQuote(symbol = 'SPY') {
    try {
      const response = await axios.get(this.baseUrl, {
        params: {
          function: 'GLOBAL_QUOTE',
          symbol,
          apikey: this.apiKey,
        },
        timeout: 10000,
      });

      const quote = response.data['Global Quote'];

      if (!quote) {
        throw new Error('Invalid response from Alpha Vantage');
      }

      logger.info('Fetched stock quote', { symbol, price: quote['05. price'] });

      return {
        source: 'AlphaVantage',
        type: 'stock',
        symbol,
        data: {
          symbol: quote['01. symbol'],
          price: parseFloat(quote['05. price']),
          change: parseFloat(quote['09. change']),
          changePercent: quote['10. change percent'],
          volume: parseInt(quote['06. volume']),
          lastTrade: quote['07. latest trading day'],
        },
        fetchedAt: new Date().toISOString(),
      };
    } catch (error) {
      logger.error('Stock quote fetch error', { error: error.message });
      throw new Error(`Failed to fetch stock quote: ${error.message}`);
    }
  }

  async getMarketOverview() {
    const symbols = ['SPY', 'QQQ', 'DIA']; // S&P 500, NASDAQ, DOW

    try {
      const quotes = await Promise.allSettled(
        symbols.map((symbol) => this.getQuote(symbol))
      );

      const successfulQuotes = quotes
        .filter((result) => result.status === 'fulfilled')
        .map((result) => result.value.data);

      logger.info('Fetched market overview', { count: successfulQuotes.length });

      return {
        source: 'AlphaVantage',
        type: 'stock',
        data: successfulQuotes,
        fetchedAt: new Date().toISOString(),
      };
    } catch (error) {
      logger.error('Market overview fetch error', { error: error.message });
      throw new Error(`Failed to fetch market overview: ${error.message}`);
    }
  }
}

/**
 * Update data source status in database
 */
export async function updateDataSourceStatus(sourceName, status, error = null) {
  try {
    await query(
      `UPDATE data_sources
       SET last_fetch_at = CURRENT_TIMESTAMP,
           last_error = $2
       WHERE source_name = $1`,
      [sourceName, error]
    );
  } catch (err) {
    logger.error('Failed to update data source status', { error: err.message });
  }
}

/**
 * Main fetcher that coordinates all data sources
 */
export async function fetchAllData() {
  logger.info('Starting data fetch cycle');

  const results = {
    news: null,
    stocks: null,
    errors: [],
  };

  // Fetch news
  try {
    const newsFetcher = new NewsFetcher();
    results.news = await newsFetcher.fetchTechNews();
    await updateDataSourceStatus('NewsAPI', 'success');
  } catch (error) {
    logger.error('Failed to fetch news', { error: error.message });
    results.errors.push({ source: 'news', error: error.message });
    await updateDataSourceStatus('NewsAPI', 'error', error.message);
  }

  // Fetch stocks
  try {
    const stockFetcher = new StockFetcher();
    results.stocks = await stockFetcher.getMarketOverview();
    await updateDataSourceStatus('Alpha Vantage', 'success');
  } catch (error) {
    logger.error('Failed to fetch stocks', { error: error.message });
    results.errors.push({ source: 'stocks', error: error.message });
    await updateDataSourceStatus('Alpha Vantage', 'error', error.message);
  }

  logger.info('Data fetch cycle completed', {
    newsCount: results.news?.data?.length || 0,
    stockCount: results.stocks?.data?.length || 0,
    errorCount: results.errors.length,
  });

  return results;
}
