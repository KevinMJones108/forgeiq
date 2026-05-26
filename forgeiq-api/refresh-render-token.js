#!/usr/bin/env node
const https = require('https');

const REFRESH_TOKEN = process.env.RENDER_REFRESH_TOKEN;
if (!REFRESH_TOKEN) { console.error('RENDER_REFRESH_TOKEN not set — see forgeiq-api/.env'); process.exit(1); }

function refreshToken() {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      refresh_token: REFRESH_TOKEN
    });

    const options = {
      hostname: 'api.render.com',
      port: 443,
      path: '/v1/refresh-token',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          const result = JSON.parse(body);
          console.log(result.api_key);
          resolve(result.api_key);
        } else {
          console.error('Error:', body);
          reject(new Error(`Failed to refresh token: ${res.statusCode}`));
        }
      });
    });

    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

refreshToken().catch(err => {
  console.error('Failed:', err.message);
  process.exit(1);
});
