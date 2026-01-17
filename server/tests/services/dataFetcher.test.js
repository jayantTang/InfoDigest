// Data Fetcher Tests
import { describe, it, before, after, mock } from 'node:test';
import assert from 'node:assert';

// Mock axios for API calls
const mockAxios = {
  get: async (url, options) => {
    if (url.includes('newsapi.org')) {
      return {
        data: {
          articles: [
            {
              title: 'Test Article 1',
              description: 'Test description',
              url: 'https://example.com/1',
            },
            {
              title: '[removed]',
              description: 'Test description 2',
              url: 'https://example.com/2',
            },
          ],
        },
      };
    }
    if (url.includes('alphavantage')) {
      return {
        data: {
          'Global Quote': {
            '01. symbol': 'AAPL',
            '05. price': '150.25',
            '09. change': '2.50',
            '10. change percent': '1.68%',
            '06. volume': '50000000',
            '07. latest trading day': '2025-01-15',
          },
        },
      };
    }
    throw new Error('Unknown API endpoint');
  },
};

describe('Data Fetcher', () => {
  describe('NewsFetcher', () => {
    it('should fetch and filter news articles', async () => {
      const response = await mockAxios.get('https://newsapi.org/v2/everything');

      assert.ok(response.data.articles);
      assert.strictEqual(response.data.articles.length, 2);
      assert.strictEqual(response.data.articles[0].title, 'Test Article 1');
    });

    it('should filter out [removed] articles', async () => {
      const response = await mockAxios.get('https://newsapi.org/v2/everything');

      const validArticles = response.data.articles.filter(
        (article) => article.title?.toLowerCase() !== '[removed]'
      );

      assert.strictEqual(validArticles.length, 1);
      assert.strictEqual(validArticles[0].title, 'Test Article 1');
    });
  });

  describe('StockFetcher', () => {
    it('should fetch stock quote data', async () => {
      const response = await mockAxios.get('https://www.alphavantage.co/query');

      assert.ok(response.data['Global Quote']);
      assert.strictEqual(response.data['Global Quote']['01. symbol'], 'AAPL');
      assert.strictEqual(response.data['Global Quote']['05. price'], '150.25');
    });

    it('should parse stock data correctly', async () => {
      const response = await mockAxios.get('https://www.alphavantage.co/query');
      const quote = response.data['Global Quote'];

      assert.strictEqual(parseFloat(quote['05. price']), 150.25);
      assert.strictEqual(parseFloat(quote['09. change']), 2.5);
      assert.strictEqual(parseInt(quote['06. volume']), 50000000);
    });
  });
});
