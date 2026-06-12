const { test, before, after } = require('node:test');
const assert = require('node:assert');

const app = require('../src/app');

let server;
let baseUrl;

before(async () => {
  await new Promise((resolve) => {
    server = app.listen(0, () => {
      baseUrl = `http://127.0.0.1:${server.address().port}`;
      resolve();
    });
  });
});

after(() => {
  server.close();
});

test('GET /health returns 200 with the standard envelope', async () => {
  const res = await fetch(`${baseUrl}/health`);
  assert.strictEqual(res.status, 200);
  const body = await res.json();
  assert.strictEqual(body.success, true);
  assert.strictEqual(body.data.status, 'ok');
});

test('protected routes return 401 JSON without a JWT', async () => {
  const routes = [
    ['GET', '/api/v1/voice/recordings'],
    ['POST', '/api/v1/voice/tts'],
    ['POST', '/api/v1/ai/call-summary'],
    ['GET', '/api/v1/ai/rep-stats'],
    ['POST', '/api/v1/crm/log-call'],
    ['GET', '/api/v1/auth/me'],
    ['POST', '/api/v1/ideas/extract'],
    ['POST', '/api/v1/sigma/test'],
    ['POST', '/api/v1/forge/scripts'],
    ['POST', '/api/v1/vapi/call']
  ];
  for (const [method, path] of routes) {
    const res = await fetch(`${baseUrl}${path}`, { method });
    assert.strictEqual(res.status, 401, `${method} ${path} should be 401`);
    const body = await res.json();
    assert.strictEqual(body.success, false, `${method} ${path} should return JSON envelope`);
  }
});

test('unknown route returns 404 JSON, never plain text', async () => {
  const res = await fetch(`${baseUrl}/definitely-not-a-route`);
  assert.strictEqual(res.status, 404);
  assert.match(res.headers.get('content-type'), /application\/json/);
  const body = await res.json();
  assert.strictEqual(body.success, false);
});
