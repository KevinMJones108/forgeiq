# ForgeIQ Backend — Render Deployment

## Prerequisites
- GitHub repo (create private: github.com/KevinMJones108/forgeiq)
- Render account (dashboard.render.com)
- Auth0 tenant configured (see Session 9 instructions)

## Step 1: Push to GitHub
```bash
cd ~/qbo/forgeiq
git init
git add .
git commit -m "Initial ForgeIQ project scaffold + Session 8 backend"
git branch -M main
git remote add origin git@github.com:KevinMJones108/forgeiq.git
git push -u origin main
```

## Step 2: Connect Render
1. Go to dashboard.render.com
2. New → Blueprint
3. Connect repo: KevinMJones108/forgeiq
4. Render reads render.yaml automatically
5. Creates: forgeiq-api (Web Service) + forgeiq-db (PostgreSQL)

## Step 3: Set Environment Variables
In Render Dashboard → forgeiq-api → Environment:

| Variable | Value | Source |
|----------|-------|--------|
| AUTH0_DOMAIN | [tenant].auth0.com | Auth0 dashboard |
| AUTH0_AUDIENCE | [API identifier] | Auth0 dashboard |
| ELEVEN_LABS_API_KEY | [key] | elevenlabs.io account |
| ANTHROPIC_API_KEY | sk-ant-api03-Uxyzq...Qmg | ~/.anthropic_api_key |
| PIPEDRIVE_API_TOKEN | [token] | app.pipedrive.com → API |
| VAPI_API_KEY | d62b9f7d-3a17-448c-b26c-acdcca0ea827 | From .env |

DATABASE_URL auto-filled by Render PostgreSQL.

## Step 4: Deploy
- Render auto-deploys on push to main
- First deploy: ~3 minutes
- Schema migration runs automatically on startup

## Step 5: Verify
```bash
BASE=https://forgeiq-api.onrender.com
curl $BASE/health
# Expect: {"success": true, "data": {"status": "ok"}}

curl $BASE/api/v1/ideas
# Expect: 401 Unauthorized (correct, needs JWT)
```

## Update iOS App
In ForgeIQ/Shared/Constants.swift:
```swift
#else
static let API_BASE_URL = "https://forgeiq-api.onrender.com"
#endif
```

## Cost
- Web Service: $7/mo (Starter)
- PostgreSQL: $7/mo (Starter)
- Total: $14/mo

## Auto-Deploy
Push to main → Render deploys automatically.
No manual deploy needed.

## Logs
Render Dashboard → forgeiq-api → Logs (real-time)

## Database Access
```bash
# From Render dashboard → forgeiq-db → Connect
psql [connection string from Render]
```
