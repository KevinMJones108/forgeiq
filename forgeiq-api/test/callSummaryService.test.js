const { test } = require('node:test');
const assert = require('node:assert');
const { isReEngagementCandidate, normaliseSummary } = require('../src/services/callSummaryService');

function summary(overrides = {}) {
  return {
    summary: 's',
    went_well: [],
    learning_points: [],
    blown_past: [],
    commitments: [],
    next_step: '',
    call_score: 8,
    talk_time_rep_pct: 40,
    talk_time_prospect_pct: 60,
    ...overrides
  };
}

test('re-engagement: score < 5 flags the call', () => {
  assert.strictEqual(isReEngagementCandidate(summary({ call_score: 4 })), true);
  assert.strictEqual(isReEngagementCandidate(summary({ call_score: 5 })), false);
});

test('re-engagement: 2+ HIGH blown past signals flag the call', () => {
  const high = { signal_type: 'HIGH' };
  const med = { signal_type: 'MED' };
  assert.strictEqual(isReEngagementCandidate(summary({ blown_past: [high, high] })), true);
  assert.strictEqual(isReEngagementCandidate(summary({ blown_past: [high, med] })), false);
});

test('re-engagement: signal_type is case-insensitive', () => {
  const high = { signal_type: 'high' };
  assert.strictEqual(isReEngagementCandidate(summary({ blown_past: [high, high] })), true);
});

test('normaliseSummary fills missing fields with safe defaults', () => {
  const result = normaliseSummary({});
  assert.strictEqual(result.summary, '');
  assert.deepStrictEqual(result.went_well, []);
  assert.deepStrictEqual(result.blown_past, []);
  assert.strictEqual(result.call_score, null);
  assert.strictEqual(result.talk_time_rep_pct, null);
});

test('normaliseSummary rounds numeric fields', () => {
  const result = normaliseSummary({ call_score: 7.6, talk_time_rep_pct: 38.2, talk_time_prospect_pct: 61.8 });
  assert.strictEqual(result.call_score, 8);
  assert.strictEqual(result.talk_time_rep_pct, 38);
  assert.strictEqual(result.talk_time_prospect_pct, 62);
});
