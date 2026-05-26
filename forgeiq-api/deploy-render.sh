#!/bin/bash
# ForgeIQ Render Deployment Automation
# Born 2026-05-25 — Deploy backend + PostgreSQL to Render via API

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Extract API key
RENDER_API_KEY=$(cat ~/.render/cli.yaml | grep 'key:' | awk '{print $2}')

if [ -z "$RENDER_API_KEY" ]; then
  echo -e "${RED}ERROR: Render API key not found at ~/.render/cli.yaml${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Render API key loaded${NC}"

# Check if .env exists for secret values
if [ ! -f .env ]; then
  echo -e "${RED}ERROR: .env file not found. Copy .env.example and fill in secrets.${NC}"
  exit 1
fi

# Source .env for secret values
set -a
source .env
set +a

echo -e "${GREEN}✓ Environment variables loaded${NC}"

# GitHub repo
GITHUB_REPO="https://github.com/KevinMJones108/forgeiq"
GITHUB_BRANCH="main"

# API base
API_BASE="https://api.render.com/v1"

# ============================================
# STEP 1: Check if service already exists
# ============================================

echo -e "${YELLOW}Checking if forgeiq-api service already exists...${NC}"

EXISTING_SERVICE=$(curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
  "$API_BASE/services?name=forgeiq-api" | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"//;s/"//')

if [ -n "$EXISTING_SERVICE" ]; then
  echo -e "${YELLOW}Service already exists: $EXISTING_SERVICE${NC}"
  SERVICE_ID="$EXISTING_SERVICE"
else
  echo -e "${YELLOW}Service does not exist. Creating...${NC}"

  # ============================================
  # STEP 2: Create PostgreSQL database
  # ============================================

  echo -e "${YELLOW}Creating PostgreSQL database: forgeiq-db${NC}"

  DB_RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer $RENDER_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "forgeiq-db",
      "databaseName": "forgeiq",
      "databaseUser": "forgeiq_user",
      "plan": "starter",
      "region": "oregon"
    }' \
    "$API_BASE/postgres")

  DB_ID=$(echo "$DB_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"//;s/"//')

  if [ -z "$DB_ID" ]; then
    echo -e "${RED}ERROR: Failed to create database${NC}"
    echo "$DB_RESPONSE"
    exit 1
  fi

  echo -e "${GREEN}✓ Database created: $DB_ID${NC}"
  echo -e "${YELLOW}Waiting 30s for database to provision...${NC}"
  sleep 30

  # Get database connection string
  DB_INFO=$(curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
    "$API_BASE/postgres/$DB_ID")

  DATABASE_URL=$(echo "$DB_INFO" | grep -o '"connectionString":"[^"]*"' | head -1 | sed 's/"connectionString":"//;s/"//')

  if [ -z "$DATABASE_URL" ]; then
    echo -e "${RED}ERROR: Could not retrieve DATABASE_URL${NC}"
    exit 1
  fi

  echo -e "${GREEN}✓ Database URL retrieved${NC}"

  # ============================================
  # STEP 3: Create Web Service
  # ============================================

  echo -e "${YELLOW}Creating web service: forgeiq-api${NC}"

  SERVICE_RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer $RENDER_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
      "type": "web_service",
      "name": "forgeiq-api",
      "runtime": "node",
      "repo": "'"$GITHUB_REPO"'",
      "branch": "'"$GITHUB_BRANCH"'",
      "rootDir": "forgeiq-api",
      "buildCommand": "npm install",
      "startCommand": "node src/server.js",
      "healthCheckPath": "/health",
      "plan": "starter",
      "region": "oregon",
      "autoDeploy": true,
      "envVars": [
        {"key": "NODE_ENV", "value": "production"},
        {"key": "PORT", "value": "3001"},
        {"key": "DATABASE_URL", "value": "'"$DATABASE_URL"'"},
        {"key": "AUTH0_DOMAIN", "value": "'"$AUTH0_DOMAIN"'"},
        {"key": "AUTH0_AUDIENCE", "value": "'"$AUTH0_AUDIENCE"'"},
        {"key": "AUTH0_CLIENT_ID", "value": "'"$AUTH0_CLIENT_ID"'"},
        {"key": "ELEVEN_LABS_API_KEY", "value": "'"$ELEVEN_LABS_API_KEY"'"},
        {"key": "ANTHROPIC_API_KEY", "value": "'"$ANTHROPIC_API_KEY"'"},
        {"key": "PIPEDRIVE_API_TOKEN", "value": "'"$PIPEDRIVE_API_TOKEN"'"},
        {"key": "VAPI_API_KEY", "value": "'"$VAPI_API_KEY"'"},
        {"key": "STRIPE_SECRET_KEY", "value": "'"$STRIPE_SECRET_KEY"'"}
      ]
    }' \
    "$API_BASE/services")

  SERVICE_ID=$(echo "$SERVICE_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"//;s/"//')

  if [ -z "$SERVICE_ID" ]; then
    echo -e "${RED}ERROR: Failed to create service${NC}"
    echo "$SERVICE_RESPONSE"
    exit 1
  fi

  echo -e "${GREEN}✓ Service created: $SERVICE_ID${NC}"
fi

# ============================================
# STEP 4: Trigger Deploy
# ============================================

echo -e "${YELLOW}Triggering deployment...${NC}"

DEPLOY_RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $RENDER_API_KEY" \
  -H "Content-Type: application/json" \
  "$API_BASE/services/$SERVICE_ID/deploys")

DEPLOY_ID=$(echo "$DEPLOY_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"//;s/"//')

if [ -z "$DEPLOY_ID" ]; then
  echo -e "${RED}ERROR: Failed to trigger deployment${NC}"
  echo "$DEPLOY_RESPONSE"
  exit 1
fi

echo -e "${GREEN}✓ Deployment triggered: $DEPLOY_ID${NC}"

# ============================================
# STEP 5: Wait for deployment
# ============================================

echo -e "${YELLOW}Waiting for deployment to complete (max 5 min)...${NC}"

MAX_WAIT=300
ELAPSED=0
INTERVAL=10

while [ $ELAPSED -lt $MAX_WAIT ]; do
  DEPLOY_STATUS=$(curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
    "$API_BASE/services/$SERVICE_ID/deploys/$DEPLOY_ID" | grep -o '"status":"[^"]*"' | head -1 | sed 's/"status":"//;s/"//')

  if [ "$DEPLOY_STATUS" = "live" ]; then
    echo -e "${GREEN}✓ Deployment successful!${NC}"
    break
  elif [ "$DEPLOY_STATUS" = "build_failed" ] || [ "$DEPLOY_STATUS" = "deploy_failed" ]; then
    echo -e "${RED}ERROR: Deployment failed with status: $DEPLOY_STATUS${NC}"
    exit 1
  fi

  echo -e "${YELLOW}Status: $DEPLOY_STATUS (${ELAPSED}s elapsed)${NC}"
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

if [ $ELAPSED -ge $MAX_WAIT ]; then
  echo -e "${RED}ERROR: Deployment timed out after ${MAX_WAIT}s${NC}"
  exit 1
fi

# ============================================
# STEP 6: Get service URL
# ============================================

SERVICE_INFO=$(curl -s -H "Authorization: Bearer $RENDER_API_KEY" \
  "$API_BASE/services/$SERVICE_ID")

SERVICE_URL=$(echo "$SERVICE_INFO" | grep -o '"serviceUrl":"[^"]*"' | head -1 | sed 's/"serviceUrl":"//;s/"//')

if [ -z "$SERVICE_URL" ]; then
  echo -e "${RED}ERROR: Could not retrieve service URL${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ ForgeIQ API LIVE${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}URL: $SERVICE_URL${NC}"
echo -e "${GREEN}Health check: $SERVICE_URL/health${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

exit 0
