#!/bin/bash
# Reads RENDER_API_KEY from environment.
# Source forgeiq-api/.env first:  set -a; source .env; set +a
set -e

API_KEY="${RENDER_API_KEY:?RENDER_API_KEY not set — source forgeiq-api/.env first}"
REPO_URL="https://github.com/KevinMJones108/forgeiq"

echo "🚀 ForgeIQ Render Deployment via API"
echo ""

# Get owner ID
echo "1/4 Getting owner ID..."
OWNER_ID=$(curl -s -H "Authorization: Bearer $API_KEY" https://api.render.com/v1/owners | python3 -c "import sys, json; print(json.load(sys.stdin)[0]['owner']['id'])")
echo "✓ Owner ID: $OWNER_ID"

# Create PostgreSQL database
echo ""
echo "2/4 Creating PostgreSQL database..."
DB_RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  https://api.render.com/v1/postgres \
  -d "{
    \"ownerId\": \"$OWNER_ID\",
    \"name\": \"forgeiq-db\",
    \"plan\": \"free\",
    \"region\": \"oregon\",
    \"version\": \"15\",
    \"databaseName\": \"forgeiq\",
    \"databaseUser\": \"forgeiq\"
  }")

DB_ID=$(echo "$DB_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('id', 'ERROR'))" 2>/dev/null || echo "ERROR")

if [ "$DB_ID" = "ERROR" ]; then
  echo "✗ Database creation failed"
  echo "$DB_RESPONSE"
  exit 1
fi

echo "✓ Database created: $DB_ID"

# Wait for database to be ready
echo "⏳ Waiting for database to initialize (30s)..."
sleep 30

# Get database connection string
DB_URL=$(curl -s -H "Authorization: Bearer $API_KEY" https://api.render.com/v1/postgres/$DB_ID | python3 -c "import sys, json; print(json.load(sys.stdin)['connectionInfo']['externalConnectionString'])")

# Create web service
echo ""
echo "3/4 Creating web service..."

# Read API keys from .env
ANTHROPIC_KEY=$(grep ANTHROPIC_API_KEY .env | cut -d'=' -f2)
ELEVEN_KEY=$(grep ELEVEN_LABS_API_KEY .env | cut -d'=' -f2)

WEB_RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  https://api.render.com/v1/services \
  -d "{
    \"type\": \"web_service\",
    \"ownerId\": \"$OWNER_ID\",
    \"name\": \"forgeiq-api\",
    \"repo\": \"$REPO_URL\",
    \"autoDeploy\": true,
    \"branch\": \"main\",
    \"rootDir\": \"forgeiq-api\",
    \"buildCommand\": \"npm install\",
    \"startCommand\": \"node src/server.js\",
    \"plan\": \"starter\",
    \"region\": \"oregon\",
    \"envVars\": [
      {\"key\": \"NODE_ENV\", \"value\": \"production\"},
      {\"key\": \"PORT\", \"value\": \"3001\"},
      {\"key\": \"DATABASE_URL\", \"value\": \"$DB_URL\"},
      {\"key\": \"ANTHROPIC_API_KEY\", \"value\": \"$ANTHROPIC_KEY\"},
      {\"key\": \"ELEVEN_LABS_API_KEY\", \"value\": \"$ELEVEN_KEY\"},
      {\"key\": \"AUTH0_DOMAIN\", \"value\": \"\"},
      {\"key\": \"AUTH0_CLIENT_ID\", \"value\": \"\"},
      {\"key\": \"AUTH0_AUDIENCE\", \"value\": \"\"}
    ]
  }")

SERVICE_ID=$(echo "$WEB_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('service', {}).get('id', 'ERROR'))" 2>/dev/null || echo "ERROR")

if [ "$SERVICE_ID" = "ERROR" ]; then
  echo "✗ Service creation failed"
  echo "$WEB_RESPONSE"
  exit 1
fi

echo "✓ Service created: $SERVICE_ID"

# Get service URL
SERVICE_URL=$(echo "$WEB_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d['service']['serviceDetails']['url'])")

echo ""
echo "4/4 Deployment initiated"
echo ""
echo "✅ RENDER DEPLOYMENT COMPLETE"
echo ""
echo "Service URL: https://$SERVICE_URL"
echo "Database: $DB_ID"
echo ""
echo "⏳ Initial build will take 3-5 minutes"
echo "   Monitor at: https://dashboard.render.com/web/$SERVICE_ID"
echo ""
