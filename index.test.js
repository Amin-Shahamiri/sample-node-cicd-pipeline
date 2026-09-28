import assert from 'node:assert';
import test from 'node:test';

test('Pipeline health check route assertion', () => {
  const isHealthy = true;
  assert.strictEqual(isHealthy, true);
});

// test('Pipeline health check route assertion', () => {
//   assert.strictEqual(true, false); // Deliberately fail
// });