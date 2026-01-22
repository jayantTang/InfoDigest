import { describe, it } from 'node:test';
import assert from 'node:assert';
import calculator from '../priceChangeCalculator.js';

describe('PriceChangeCalculator', () => {
  describe('getPriceAt', () => {
    it('should return price from N days ago', async () => {
      const price = await calculator.getPriceAt('000001.SS', 1);
      assert.ok(price > 0, 'Price should be greater than 0');
    });

    it('should return null for symbol with no history', async () => {
      const price = await calculator.getPriceAt('INVALID.SS', 7);
      assert.strictEqual(price, null, 'Price should be null for invalid symbol');
    });
  });

  describe('calculatePriceChange', () => {
    it('should calculate price changes for all periods', async () => {
      const changes = await calculator.calculatePriceChange('000001.SS');

      assert.ok(changes.hasOwnProperty('1d'), 'Should have 1d period');
      assert.ok(changes.hasOwnProperty('1w'), 'Should have 1w period');
      assert.ok(changes.hasOwnProperty('1m'), 'Should have 1m period');
      assert.ok(changes.hasOwnProperty('3m'), 'Should have 3m period');
      assert.ok(changes.hasOwnProperty('1y'), 'Should have 1y period');
      assert.ok(changes.hasOwnProperty('3y'), 'Should have 3y period');
    });

    it('should return correct format for available data', async () => {
      const changes = await calculator.calculatePriceChange('000001.SS');

      if (changes['1d'].available) {
        assert.match(changes['1d'].value, /^[\+\-]\d+\.\d$/, 'Value should match format +2.5 or -0.8');
      }
    });
  });
});
