const { test } = require('node:test');
const assert = require('node:assert');
const { success, error } = require('../src/utils/response');

test('success() returns the standard envelope', () => {
  const result = success({ foo: 1 });
  assert.deepStrictEqual(result, { success: true, data: { foo: 1 }, error: null });
});

test('error() returns the standard envelope', () => {
  const result = error('nope');
  assert.deepStrictEqual(result, { success: false, data: null, error: 'nope' });
});
