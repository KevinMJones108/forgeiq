#!/usr/bin/env node
// ForgeIQ — Render deploy via API (run from GitHub Actions: deploy-render.yml)
// Creates forgeiq-db (Postgres, free) + forgeiq-api (web service) with clean
// names, deleting stale never-live squatters first. Never prints secrets.

const API = 'https://api.render.com/v1';
const KEY = process.env.RENDER_API_KEY;
const REPO_URL = 'https://github.com/KevinMJones108/forgeiq';
const BRANCH = process.env.DEPLOY_BRANCH || 'claude/pensive-hopper-ixUSw';
const REGION = 'oregon';

if (!KEY) {
  console.error('RENDER_API_KEY not set');
  process.exit(1);
}

async function api(method, path, body) {
  const res = await fetch(`${API}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${KEY}`,
      'Content-Type': 'application/json',
      Accept: 'application/json'
    },
    body: body ? JSON.stringify(body) : undefined
  });
  const text = await res.text();
  let json = null;
  try { json = JSON.parse(text); } catch { /* non-JSON */ }
  return { status: res.status, json, text };
}

function fail(msg, extra) {
  console.error(`DEPLOY FAILED: ${msg}`);
  if (extra) console.error(extra);
  process.exit(1);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function main() {
  // 1. Owner
  const owners = await api('GET', '/owners?limit=10');
  if (owners.status !== 200) fail(`auth check failed (HTTP ${owners.status}) — API key invalid or revoked?`);
  const owner = owners.json.map((o) => o.owner).find((o) => o) || null;
  if (!owner) fail('no owner found for this API key');
  console.log(`Owner: ${owner.name} (${owner.id})`);

  // 2. Idempotency: if forgeiq-api already exists and has been live, do NOT
  // touch anything — this guard makes accidental re-runs harmless.
  const services = await api('GET', '/services?limit=100');
  if (services.status !== 200) fail(`list services failed (HTTP ${services.status})`);
  for (const item of services.json) {
    const s = item.service;
    if (s.name !== 'forgeiq-api') continue;
    const deploys = await api('GET', `/services/${s.id}/deploys?limit=20`);
    const everLive = (deploys.json || []).some((d) => d.deploy && d.deploy.status === 'live');
    if (everLive) {
      console.log(`forgeiq-api (${s.id}) already exists and has been live — nothing to do.`);
      console.log('Re-deploys happen automatically on git push (autoDeploy: yes).');
      return;
    }
    console.log(`Deleting stale service forgeiq-api (${s.id}, created ${s.createdAt}, never live)`);
    const del = await api('DELETE', `/services/${s.id}`);
    if (del.status !== 204 && del.status !== 200) fail(`delete service failed (HTTP ${del.status})`, del.text);
  }

  // Only delete a leftover forgeiq-db when no live forgeiq-api exists (above
  // guard already returned otherwise) AND we are about to recreate the stack.
  const pgList = await api('GET', '/postgres?limit=100');
  if (pgList.status === 200) {
    for (const item of pgList.json) {
      const p = item.postgres;
      if (p.name !== 'forgeiq-db') continue;
      console.log(`Deleting stale postgres forgeiq-db (${p.id}, status ${p.status})`);
      const del = await api('DELETE', `/postgres/${p.id}`);
      if (del.status !== 204 && del.status !== 200) fail(`delete postgres failed (HTTP ${del.status})`, del.text);
    }
  }

  // 3. Create Postgres (free plan)
  console.log('Creating postgres forgeiq-db (plan: free)...');
  const pg = await api('POST', '/postgres', {
    name: 'forgeiq-db',
    ownerId: owner.id,
    plan: 'free',
    region: REGION,
    version: '16',
    databaseName: 'forgeiq',
    databaseUser: 'forgeiq_user'
  });
  if (pg.status !== 201) fail(`create postgres failed (HTTP ${pg.status})`, pg.text);
  const pgId = pg.json.id;

  // 4. Wait until available
  let pgStatus = '';
  for (let i = 0; i < 60; i++) {
    await sleep(10000);
    const info = await api('GET', `/postgres/${pgId}`);
    pgStatus = info.json?.status;
    console.log(`postgres status: ${pgStatus}`);
    if (pgStatus === 'available') break;
  }
  if (pgStatus !== 'available') fail('postgres did not become available in 10 minutes');

  const conn = await api('GET', `/postgres/${pgId}/connection-info`);
  if (conn.status !== 200 || !conn.json.internalConnectionString) fail(`could not get connection info (HTTP ${conn.status})`);
  const dbUrl = conn.json.internalConnectionString;
  console.log('Got internal database connection string (not printed).');

  // 5. Create web service
  console.log('Creating web service forgeiq-api...');
  const svc = await api('POST', '/services', {
    type: 'web_service',
    name: 'forgeiq-api',
    ownerId: owner.id,
    repo: REPO_URL,
    branch: BRANCH,
    autoDeploy: 'yes',
    rootDir: 'forgeiq-api',
    serviceDetails: {
      env: 'node',
      plan: 'starter',
      region: REGION,
      healthCheckPath: '/health',
      envSpecificDetails: {
        buildCommand: 'npm install',
        startCommand: 'node src/server.js'
      }
    },
    envVars: [
      { key: 'NODE_ENV', value: 'production' },
      { key: 'DATABASE_URL', value: dbUrl },
      { key: 'AUTH0_DOMAIN', value: 'dev-yjrvxlswm4yk3zz7.auth0.com' },
      { key: 'AUTH0_AUDIENCE', value: 'https://forgeiq-api.onrender.com' },
      { key: 'ELEVEN_LABS_API_KEY', value: 'pending' },
      { key: 'ANTHROPIC_API_KEY', value: 'pending' },
      { key: 'PIPEDRIVE_API_TOKEN', value: 'pending' }
    ]
  });
  if (svc.status !== 201) fail(`create service failed (HTTP ${svc.status})`, svc.text);
  const serviceId = svc.json.service?.id || svc.json.id;
  const serviceUrl = svc.json.service?.serviceDetails?.url || 'https://forgeiq-api.onrender.com';
  console.log(`Service created: ${serviceId} → ${serviceUrl}`);

  // 6. Wait for first deploy to go live
  let live = false;
  for (let i = 0; i < 90; i++) {
    await sleep(10000);
    const deploys = await api('GET', `/services/${serviceId}/deploys?limit=1`);
    const d = deploys.json?.[0]?.deploy;
    console.log(`deploy status: ${d?.status || 'unknown'}`);
    if (d?.status === 'live') { live = true; break; }
    if (['build_failed', 'update_failed', 'deactivated', 'canceled'].includes(d?.status)) {
      fail(`deploy ended in status: ${d.status} — check Render dashboard logs`);
    }
  }
  if (!live) fail('deploy did not go live within 15 minutes');

  // 7. Health check
  const health = await fetch(`${serviceUrl}/health`).then((r) => r.json()).catch((e) => ({ error: String(e) }));
  console.log('Health check:', JSON.stringify(health));
  if (!health.success) fail('health endpoint did not return success:true');

  console.log('');
  console.log('========================================');
  console.log(`✅ BACKEND LIVE: ${serviceUrl}`);
  console.log('Remaining manual steps:');
  console.log('  1. Set real ELEVEN_LABS_API_KEY / ANTHROPIC_API_KEY / PIPEDRIVE_API_TOKEN');
  console.log('     in Render dashboard → forgeiq-api → Environment (currently "pending")');
  console.log('  2. Auth0 dashboard: add callback URL (see SETUP_COPY_PASTE.txt)');
  console.log('========================================');
}

main().catch((e) => fail(e.message, e.stack));
