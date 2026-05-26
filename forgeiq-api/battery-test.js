#!/usr/bin/env node
/**
 * ForgeIQ VoiceCore Battery Test
 * Tests 100 recording scenarios at 99.5%+ pass rate (5σ target)
 * Per Kevin's 1,000-test gate rule (scaled to 100 for Phase 1)
 */

const axios = require('axios');
const fs = require('fs').promises;
const path = require('path');

// Configuration
const API_BASE = process.env.API_BASE_URL || 'http://localhost:3001';
const AUTH0_DOMAIN = process.env.AUTH0_DOMAIN;
const AUTH0_CLIENT_ID = process.env.AUTH0_CLIENT_ID;
const AUTH0_CLIENT_SECRET = process.env.AUTH0_CLIENT_SECRET;
const TEST_USER_EMAIL = 'battery-test@forgeiq.test';
const TEST_USER_PASSWORD = process.env.BATTERY_TEST_PASSWORD || 'BatteryTest123!';

// Test scenarios (100 variations)
const TEST_SCENARIOS = generateScenarios();

// Results tracking
const results = {
  total: 0,
  passed: 0,
  failed: 0,
  failures: [],
  startTime: null,
  endTime: null
};

function generateScenarios() {
  const scenarios = [];

  // 40 English sales calls (primary use case)
  for (let i = 1; i <= 40; i++) {
    scenarios.push({
      id: `EN-SALES-${String(i).padStart(2, '0')}`,
      language: 'en-US',
      duration: 120 + (i * 5), // 2-5 min range
      content: `Sales call ${i}: Discussing procurement needs, pricing, timeline. Customer asks about delivery, warranty, support. Rep responds with features, benefits, next steps. Close with commitment.`,
      expectedFields: ['transcript', 'language', 'duration_sec', 'created_at']
    });
  }

  // 20 Spanish calls (translation validation)
  for (let i = 1; i <= 20; i++) {
    scenarios.push({
      id: `ES-SALES-${String(i).padStart(2, '0')}`,
      language: 'es-ES',
      duration: 150 + (i * 4),
      content: `Llamada de ventas ${i}: Cliente pregunta sobre precios, entrega, garantía. Representante explica características, beneficios, próximos pasos.`,
      expectedFields: ['transcript', 'language', 'duration_sec', 'created_at']
    });
  }

  // 10 short calls (edge case: <60 sec)
  for (let i = 1; i <= 10; i++) {
    scenarios.push({
      id: `SHORT-${String(i).padStart(2, '0')}`,
      language: 'en-US',
      duration: 30 + (i * 2), // 30-50 sec
      content: `Quick call: Customer says not interested. Rep asks one qualifying question. Customer declines. End call.`,
      expectedFields: ['transcript', 'language', 'duration_sec', 'created_at']
    });
  }

  // 10 long calls (edge case: >10 min)
  for (let i = 1; i <= 10; i++) {
    scenarios.push({
      id: `LONG-${String(i).padStart(2, '0')}`,
      language: 'en-US',
      duration: 600 + (i * 30), // 10-15 min
      content: `Extended discovery call ${i}: Deep dive into customer needs, multiple stakeholders, detailed technical questions, pricing negotiation, implementation timeline discussion, objection handling, multi-step close attempt.`,
      expectedFields: ['transcript', 'language', 'duration_sec', 'created_at']
    });
  }

  // 10 French calls (multi-language validation)
  for (let i = 1; i <= 10; i++) {
    scenarios.push({
      id: `FR-SALES-${String(i).padStart(2, '0')}`,
      language: 'fr-FR',
      duration: 140 + (i * 5),
      content: `Appel commercial ${i}: Client pose des questions sur les prix, la livraison, la garantie. Le représentant explique les fonctionnalités et les avantages.`,
      expectedFields: ['transcript', 'language', 'duration_sec', 'created_at']
    });
  }

  // 10 special characters / punctuation edge cases
  for (let i = 1; i <= 10; i++) {
    scenarios.push({
      id: `SPECIAL-${String(i).padStart(2, '0')}`,
      language: 'en-US',
      duration: 120,
      content: `Call with customer: "What's the price?" "$5,000-$10,000 range." "That's 50% more than competitor!" "Let me explain... our ROI is 3-5x higher." Customer: "Hmm... okay, send proposal."`,
      expectedFields: ['transcript', 'language', 'duration_sec', 'created_at']
    });
  }

  return scenarios;
}

async function getTestToken() {
  console.log('🔐 Authenticating test user...');

  try {
    // Use Auth0 Resource Owner Password Grant for testing
    const response = await axios.post(`https://${AUTH0_DOMAIN}/oauth/token`, {
      grant_type: 'password',
      username: TEST_USER_EMAIL,
      password: TEST_USER_PASSWORD,
      client_id: AUTH0_CLIENT_ID,
      client_secret: AUTH0_CLIENT_SECRET,
      audience: process.env.AUTH0_AUDIENCE,
      scope: 'openid profile email'
    });

    console.log('✓ Auth token obtained');
    return response.data.access_token;
  } catch (error) {
    console.error('✗ Auth failed:', error.response?.data || error.message);
    throw new Error('Cannot authenticate test user. Ensure BATTERY_TEST_PASSWORD env var is set.');
  }
}

async function testScenario(scenario, token, index) {
  const scenarioNum = index + 1;
  process.stdout.write(`\r[${scenarioNum}/100] Testing ${scenario.id}...`);

  try {
    // Step 1: Create recording metadata
    const recordingResponse = await axios.post(
      `${API_BASE}/api/v1/voice/recordings`,
      {
        language: scenario.language,
        duration_sec: scenario.duration,
        title: `Battery Test ${scenario.id}`
      },
      {
        headers: { Authorization: `Bearer ${token}` },
        timeout: 10000
      }
    );

    if (!recordingResponse.data.success) {
      throw new Error('Recording creation failed: ' + JSON.stringify(recordingResponse.data));
    }

    const recordingId = recordingResponse.data.data.id;

    // Step 2: Save transcript
    const transcriptResponse = await axios.post(
      `${API_BASE}/api/v1/voice/transcripts`,
      {
        recording_id: recordingId,
        transcript: scenario.content,
        language: scenario.language
      },
      {
        headers: { Authorization: `Bearer ${token}` },
        timeout: 10000
      }
    );

    if (!transcriptResponse.data.success) {
      throw new Error('Transcript save failed: ' + JSON.stringify(transcriptResponse.data));
    }

    // Step 3: Verify transcript retrieval
    const getResponse = await axios.get(
      `${API_BASE}/api/v1/voice/recordings/${recordingId}`,
      {
        headers: { Authorization: `Bearer ${token}` },
        timeout: 10000
      }
    );

    if (!getResponse.data.success) {
      throw new Error('Transcript retrieval failed');
    }

    const retrieved = getResponse.data.data;

    // Step 4: Validate CTQ requirements
    const validations = [
      { name: 'Recording ID exists', pass: !!retrieved.id },
      { name: 'Transcript saved', pass: !!retrieved.transcript },
      { name: 'Language preserved', pass: retrieved.language === scenario.language },
      { name: 'Duration within 1%', pass: Math.abs(retrieved.duration_sec - scenario.duration) <= scenario.duration * 0.01 },
      { name: 'Content match', pass: retrieved.transcript === scenario.content },
      { name: 'Timestamp present', pass: !!retrieved.created_at }
    ];

    const allPassed = validations.every(v => v.pass);

    if (!allPassed) {
      const failedChecks = validations.filter(v => !v.pass).map(v => v.name);
      throw new Error(`Validation failed: ${failedChecks.join(', ')}`);
    }

    // PASS
    results.passed++;
    return { scenario: scenario.id, status: 'PASS' };

  } catch (error) {
    // FAIL
    results.failed++;
    const failure = {
      scenario: scenario.id,
      error: error.message,
      language: scenario.language,
      duration: scenario.duration
    };
    results.failures.push(failure);
    return { scenario: scenario.id, status: 'FAIL', error: error.message };
  }
}

async function runBatteryTest() {
  console.log('🧪 ForgeIQ VoiceCore Battery Test\n');
  console.log(`Target: 100 scenarios at ≥99.5% pass rate (5σ)\n`);

  results.startTime = new Date();

  // Get auth token
  let token;
  try {
    token = await getTestToken();
  } catch (error) {
    console.error('\n❌ Cannot start battery test without authentication');
    process.exit(1);
  }

  console.log('\n📊 Running 100 test scenarios...\n');

  // Run all scenarios sequentially (parallel would overwhelm API)
  for (let i = 0; i < TEST_SCENARIOS.length; i++) {
    results.total++;
    await testScenario(TEST_SCENARIOS[i], token, i);

    // Brief pause to avoid overwhelming backend
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  results.endTime = new Date();

  console.log('\n\n✅ Battery test complete\n');

  // Calculate metrics
  const passRate = (results.passed / results.total * 100).toFixed(2);
  const dpmo = ((results.failed / results.total) * 1000000).toFixed(0);

  // Sigma level calculation (approximate)
  let sigmaLevel;
  if (dpmo <= 3.4) sigmaLevel = '6σ';
  else if (dpmo <= 233) sigmaLevel = '5σ';
  else if (dpmo <= 6210) sigmaLevel = '4σ';
  else if (dpmo <= 66807) sigmaLevel = '3σ';
  else if (dpmo <= 308537) sigmaLevel = '2σ';
  else sigmaLevel = '<2σ';

  const duration = Math.round((results.endTime - results.startTime) / 1000);

  // Console output
  console.log('RESULTS:');
  console.log(`  Total:     ${results.total}`);
  console.log(`  Passed:    ${results.passed}`);
  console.log(`  Failed:    ${results.failed}`);
  console.log(`  Pass Rate: ${passRate}%`);
  console.log(`  DPMO:      ${dpmo}`);
  console.log(`  Sigma:     ${sigmaLevel}`);
  console.log(`  Duration:  ${duration}s\n`);

  if (parseFloat(passRate) >= 99.5) {
    console.log('✅ PASS: Battery test meets 99.5% threshold (5σ standard)\n');
  } else {
    console.log(`⚠️  FAIL: Battery test below 99.5% threshold\n`);
  }

  // Generate detailed report
  await generateReport(passRate, dpmo, sigmaLevel, duration);

  // Exit code
  process.exit(parseFloat(passRate) >= 99.5 ? 0 : 1);
}

async function generateReport(passRate, dpmo, sigmaLevel, duration) {
  const report = `# ForgeIQ VoiceCore Battery Test Results

**Date:** ${new Date().toISOString().split('T')[0]}
**Duration:** ${duration} seconds

---

## Summary

| Metric | Value |
|--------|-------|
| **Total Scenarios** | ${results.total} |
| **Passed** | ${results.passed} |
| **Failed** | ${results.failed} |
| **Pass Rate** | ${passRate}% |
| **DPMO** | ${dpmo} |
| **Sigma Level** | ${sigmaLevel} |

---

## Gate Status

${parseFloat(passRate) >= 99.5
  ? '✅ **PASS** — Battery test meets 99.5% threshold (5σ standard)'
  : '⚠️ **FAIL** — Battery test below 99.5% threshold — see failures below'}

---

## Test Scenarios Breakdown

- **40** English sales calls (2-5 min)
- **20** Spanish sales calls (translation validation)
- **10** Short calls (<60 sec edge case)
- **10** Long calls (>10 min edge case)
- **10** French sales calls (multi-language)
- **10** Special characters / punctuation edge cases

---

## CTQ Requirements Validated

1. ✓ Recording metadata saved correctly
2. ✓ Transcript saved to database
3. ✓ Transcript retrievable by ID
4. ✓ Language preserved accurately
5. ✓ Duration within 1% of expected
6. ✓ Content integrity maintained
7. ✓ Timestamps present on all records

---

${results.failures.length > 0 ? `## Failures (${results.failures.length})

${results.failures.map((f, i) => `### ${i + 1}. ${f.scenario}

- **Error:** ${f.error}
- **Language:** ${f.language}
- **Duration:** ${f.duration}s

`).join('\n')}

---

## Recommended Fixes

${generateRecommendations()}

` : '## Failures

None — all 100 scenarios passed ✅

'}

---

## Sigma Level Reference

| Sigma | DPMO | Pass Rate |
|-------|------|-----------|
| 6σ | 3.4 | 99.99966% |
| 5σ | 233 | 99.977% |
| 4σ | 6,210 | 99.379% |
| 3σ | 66,807 | 93.32% |

**Kevin's Standard:** ≥99.5% (5σ) on all systematic changes per 1000-test-gate.md

---

## Notes

Battery test validates VoiceCore module only (Phase 1 scope).
Future phases will require separate battery tests for:
- IdeaVault (Phase 2)
- SigmaVault (Phase 3)
- SalesForge (Phase 4)
- DOE Optimiser (Phase 5)
- ApexScript (Phase 6)

Generated by: forgeiq-api/battery-test.js
`;

  const reportPath = path.join(__dirname, 'BATTERY_TEST_RESULTS.md');
  await fs.writeFile(reportPath, report, 'utf8');

  console.log(`📄 Detailed report: ${reportPath}\n`);
}

function generateRecommendations() {
  if (results.failures.length === 0) return 'No fixes needed — all tests passed.';

  const recommendations = [];

  // Analyze failure patterns
  const authFailures = results.failures.filter(f => f.error.includes('auth') || f.error.includes('401')).length;
  const timeoutFailures = results.failures.filter(f => f.error.includes('timeout')).length;
  const validationFailures = results.failures.filter(f => f.error.includes('Validation failed')).length;
  const languageFailures = results.failures.filter(f => f.language !== 'en-US').length;

  if (authFailures > 0) {
    recommendations.push(`- **Auth failures (${authFailures}):** Check AUTH0_DOMAIN, CLIENT_ID, CLIENT_SECRET env vars`);
  }

  if (timeoutFailures > 0) {
    recommendations.push(`- **Timeout failures (${timeoutFailures}):** Increase timeout limits or optimize backend queries`);
  }

  if (validationFailures > 0) {
    recommendations.push(`- **Validation failures (${validationFailures}):** Review CTQ validation logic in backend`);
  }

  if (languageFailures > results.failures.length * 0.5) {
    recommendations.push(`- **Language failures (${languageFailures}):** Check translation service and language code handling`);
  }

  if (recommendations.length === 0) {
    recommendations.push('- Review individual failure logs above for specific root causes');
  }

  return recommendations.join('\n');
}

// Run battery test
runBatteryTest().catch(error => {
  console.error('\n❌ Battery test failed to run:', error.message);
  process.exit(1);
});
