// Test setup file
import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import { pool } from '../src/config/database.js';

// Global test setup
before(async () => {
  // Setup test database
  console.log('Setting up test environment...');
});

after(async () => {
  // Cleanup
  await pool.end();
  console.log('Test environment cleaned up');
});

export { describe, it, assert };
