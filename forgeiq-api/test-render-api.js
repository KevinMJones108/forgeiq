#!/usr/bin/env node
const https = require('https');

const API_KEY = process.env.RENDER_API_KEY;
if (!API_KEY) { console.error('RENDER_API_KEY not set — see forgeiq-api/.env'); process.exit(1); }

function apiCall(path) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.render.com',
      port: 443,
      path: path,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        console.log('Status:', res.statusCode);
        console.log('Response:', body);
        try {
          const parsed = JSON.parse(body);
          console.log('\nParsed:', JSON.stringify(parsed, null, 2));
          resolve(parsed);
        } catch (e) {
          console.log('\nParse error:', e.message);
          resolve(body);
        }
      });
    });

    req.on('error', reject);
    req.end();
  });
}

apiCall('/v1/owners').catch(console.error);
