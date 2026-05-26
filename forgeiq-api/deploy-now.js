#!/usr/bin/env node
const https = require('https');
const fs = require('fs');

const API_KEY = process.env.RENDER_API_KEY;
if (!API_KEY) { console.error('RENDER_API_KEY not set — see forgeiq-api/.env'); process.exit(1); }
const REPO_URL = 'https://github.com/KevinMJones108/forgeiq';

function apiCall(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.render.com',
      port: 443,
      path: path,
      method: method,
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(body));
        } catch (e) {
          resolve(body);
        }
      });
    });

    req.on('error', reject);

    if (data) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

async function deploy() {
  console.log('🚀 ForgeIQ Render Deployment\n');

  // 1. Get owner ID
  console.log('1/4 Getting owner ID...');
  const owners = await apiCall('GET', '/v1/owners');
  const ownerId = owners[0].owner.id;
  console.log(`✓ Owner ID: ${ownerId}\n`);

  // 2. Create PostgreSQL database
  console.log('2/4 Creating PostgreSQL database...');
  const dbData = {
    ownerId: ownerId,
    name: 'forgeiq-db',
    plan: 'starter',
    region: 'oregon',
    databaseName: 'forgeiq',
    databaseUser: 'forgeiq'
  };

  const dbResponse = await apiCall('POST', '/v1/postgres', dbData);
  const dbId = dbResponse.id;
  console.log(`✓ Database created: ${dbId}\n`);

  // Wait for DB to initialize
  console.log('⏳ Waiting 30s for database initialization...');
  await new Promise(resolve => setTimeout(resolve, 30000));

  // Get database connection string
  const dbInfo = await apiCall('GET', `/v1/postgres/${dbId}`);
  const dbUrl = dbInfo.connectionInfo.externalConnectionString;
  console.log('✓ Database connection string obtained\n');

  // Read API keys from .env
  const envContent = fs.readFileSync('.env', 'utf8');
  const anthropicKey = envContent.match(/ANTHROPIC_API_KEY=(.*)/)?.[1] || '';
  const elevenKey = envContent.match(/ELEVEN_LABS_API_KEY=(.*)/)?.[1] || '';

  // 3. Create web service
  console.log('3/4 Creating web service...');
  const serviceData = {
    type: 'web_service',
    ownerId: ownerId,
    name: 'forgeiq-api',
    repo: REPO_URL,
    autoDeploy: true,
    branch: 'main',
    rootDir: 'forgeiq-api',
    buildCommand: 'npm install',
    startCommand: 'node src/server.js',
    plan: 'starter',
    region: 'oregon',
    envVars: [
      { key: 'NODE_ENV', value: 'production' },
      { key: 'PORT', value: '3001' },
      { key: 'DATABASE_URL', value: dbUrl },
      { key: 'ANTHROPIC_API_KEY', value: anthropicKey },
      { key: 'ELEVEN_LABS_API_KEY', value: elevenKey },
      { key: 'AUTH0_DOMAIN', value: '' },
      { key: 'AUTH0_CLIENT_ID', value: '' },
      { key: 'AUTH0_AUDIENCE', value: '' }
    ]
  };

  const serviceResponse = await apiCall('POST', '/v1/services', serviceData);
  const serviceId = serviceResponse.service.id;
  const serviceUrl = serviceResponse.service.serviceDetails.url;

  console.log(`✓ Service created: ${serviceId}\n`);

  console.log('4/4 Deployment initiated\n');
  console.log('✅ RENDER DEPLOYMENT COMPLETE\n');
  console.log(`Service URL: https://${serviceUrl}`);
  console.log(`Database: ${dbId}\n`);
  console.log('⏳ Initial build will take 3-5 minutes');
  console.log(`   Monitor: https://dashboard.render.com/web/${serviceId}\n`);
}

deploy().catch(err => {
  console.error('❌ Deployment failed:', err.message);
  process.exit(1);
});
