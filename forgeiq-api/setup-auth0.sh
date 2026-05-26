#!/bin/bash
# ForgeIQ Auth0 Setup Automation
# Guides Kevin through Auth0 tenant and API creation
# Auto-updates Constants.swift and .env

set -e

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${BOLD}ForgeIQ Auth0 Setup${RESET}\n"

# Step 1: Open Auth0 dashboard
echo -e "${YELLOW}Step 1: Create Auth0 Tenant${RESET}"
echo "Opening Auth0 dashboard..."
open "https://manage.auth0.com/dashboard"
echo ""
echo "In the Auth0 dashboard:"
echo "  1. Click 'Create Tenant' (or use existing tenant)"
echo "  2. Tenant name: forgeiq (or your choice)"
echo "  3. Region: US (or nearest to you)"
echo "  4. Environment: Development (change to Production later)"
echo ""
read -p "Press Enter after creating tenant..."

# Step 2: Get tenant domain
echo ""
echo -e "${YELLOW}Step 2: Enter Tenant Domain${RESET}"
echo "Format: your-tenant.auth0.com (or your-tenant.us.auth0.com)"
read -p "Auth0 Domain: " AUTH0_DOMAIN

# Validate domain format
if [[ ! "$AUTH0_DOMAIN" =~ ^[a-z0-9-]+\.(us\.)?auth0\.com$ ]]; then
    echo -e "${RED}Invalid domain format. Must be: tenant.auth0.com or tenant.us.auth0.com${RESET}"
    exit 1
fi

echo -e "${GREEN}✓ Domain validated${RESET}"

# Step 3: Create API
echo ""
echo -e "${YELLOW}Step 3: Create API${RESET}"
echo "In Auth0 dashboard:"
echo "  1. Go to Applications > APIs"
echo "  2. Click 'Create API'"
echo "  3. Name: ForgeIQ API"
echo "  4. Identifier: https://forgeiq-api.onrender.com"
echo "  5. Signing Algorithm: RS256"
echo ""
read -p "Press Enter after creating API..."

# Step 4: Get API identifier
echo ""
echo -e "${YELLOW}Step 4: Enter API Identifier${RESET}"
echo "Should be: https://forgeiq-api.onrender.com"
read -p "API Identifier (Audience): " AUTH0_AUDIENCE

# Step 5: Create iOS app
echo ""
echo -e "${YELLOW}Step 5: Create iOS Application${RESET}"
echo "In Auth0 dashboard:"
echo "  1. Go to Applications > Applications"
echo "  2. Click 'Create Application'"
echo "  3. Name: ForgeIQ iOS"
echo "  4. Type: Native"
echo "  5. After creation, go to Settings tab"
echo "  6. Allowed Callback URLs: ai.alviz.forgeiq://\$AUTH0_DOMAIN/ios/ai.alviz.forgeiq/callback"
echo "  7. Allowed Logout URLs: ai.alviz.forgeiq://\$AUTH0_DOMAIN/ios/ai.alviz.forgeiq/callback"
echo "  8. Save Changes"
echo ""
read -p "Press Enter after creating iOS app..."

# Step 6: Get Client ID
echo ""
echo -e "${YELLOW}Step 6: Enter iOS Client ID${RESET}"
echo "Found in iOS app Settings > Basic Information > Client ID"
read -p "Client ID: " AUTH0_CLIENT_ID

# Validate Client ID format (alphanumeric, 32 chars)
if [[ ! "$AUTH0_CLIENT_ID" =~ ^[A-Za-z0-9]{32}$ ]]; then
    echo -e "${YELLOW}Warning: Client ID format unusual (expected 32 alphanumeric chars)${RESET}"
    read -p "Continue anyway? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}✓ Client ID validated${RESET}"

# Step 7: Update Constants.swift
echo ""
echo -e "${YELLOW}Step 7: Update iOS Constants.swift${RESET}"

CONSTANTS_PATH="../ForgeIQ/Shared/Constants.swift"

if [ ! -f "$CONSTANTS_PATH" ]; then
    echo -e "${RED}Error: Constants.swift not found at $CONSTANTS_PATH${RESET}"
    exit 1
fi

# Backup original
cp "$CONSTANTS_PATH" "${CONSTANTS_PATH}.backup"

# Update Auth0 values
sed -i '' "s|static let AUTH0_DOMAIN = \".*\"|static let AUTH0_DOMAIN = \"$AUTH0_DOMAIN\"|g" "$CONSTANTS_PATH"
sed -i '' "s|static let AUTH0_CLIENT_ID = \".*\"|static let AUTH0_CLIENT_ID = \"$AUTH0_CLIENT_ID\"|g" "$CONSTANTS_PATH"
sed -i '' "s|static let AUTH0_AUDIENCE = \".*\"|static let AUTH0_AUDIENCE = \"$AUTH0_AUDIENCE\"|g" "$CONSTANTS_PATH"

echo -e "${GREEN}✓ Constants.swift updated${RESET}"
echo "  Backup saved: ${CONSTANTS_PATH}.backup"

# Step 8: Update backend .env
echo ""
echo -e "${YELLOW}Step 8: Update Backend .env${RESET}"

ENV_PATH=".env"

if [ ! -f "$ENV_PATH" ]; then
    echo "Creating .env from .env.example..."
    cp .env.example "$ENV_PATH"
fi

# Backup original
cp "$ENV_PATH" "${ENV_PATH}.backup"

# Update Auth0 values (or add if missing)
if grep -q "^AUTH0_DOMAIN=" "$ENV_PATH"; then
    sed -i '' "s|^AUTH0_DOMAIN=.*|AUTH0_DOMAIN=$AUTH0_DOMAIN|g" "$ENV_PATH"
else
    echo "AUTH0_DOMAIN=$AUTH0_DOMAIN" >> "$ENV_PATH"
fi

if grep -q "^AUTH0_AUDIENCE=" "$ENV_PATH"; then
    sed -i '' "s|^AUTH0_AUDIENCE=.*|AUTH0_AUDIENCE=$AUTH0_AUDIENCE|g" "$ENV_PATH"
else
    echo "AUTH0_AUDIENCE=$AUTH0_AUDIENCE" >> "$ENV_PATH"
fi

if grep -q "^AUTH0_CLIENT_ID=" "$ENV_PATH"; then
    sed -i '' "s|^AUTH0_CLIENT_ID=.*|AUTH0_CLIENT_ID=$AUTH0_CLIENT_ID|g" "$ENV_PATH"
else
    echo "AUTH0_CLIENT_ID=$AUTH0_CLIENT_ID" >> "$ENV_PATH"
fi

echo -e "${GREEN}✓ .env updated${RESET}"
echo "  Backup saved: ${ENV_PATH}.backup"

# Step 9: Test JWT validation
echo ""
echo -e "${YELLOW}Step 9: Test Auth Middleware${RESET}"
echo "Starting Node.js server to test JWT validation..."

if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js not installed${RESET}"
    exit 1
fi

if [ ! -f "package.json" ]; then
    echo -e "${RED}Error: package.json not found (wrong directory?)${RESET}"
    exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Start server in background
echo "Starting server on port 3001..."
node src/server.js &
SERVER_PID=$!

# Wait for server to start
sleep 3

# Test health endpoint
echo ""
echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s http://localhost:3001/health)
if [[ "$HEALTH_RESPONSE" == *"ok"* ]]; then
    echo -e "${GREEN}✓ Health check passed${RESET}"
else
    echo -e "${RED}✗ Health check failed${RESET}"
    kill $SERVER_PID
    exit 1
fi

# Test protected endpoint without token
echo ""
echo "Testing protected endpoint without token (should fail)..."
UNAUTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/api/v1/auth/me)
if [[ "$UNAUTH_RESPONSE" == "401" ]]; then
    echo -e "${GREEN}✓ Auth middleware blocking unauthenticated requests${RESET}"
else
    echo -e "${YELLOW}Warning: Expected 401, got $UNAUTH_RESPONSE${RESET}"
fi

# Kill server
kill $SERVER_PID

# Summary
echo ""
echo -e "${BOLD}${GREEN}Auth0 Setup Complete!${RESET}\n"
echo "Configuration saved:"
echo "  iOS: $CONSTANTS_PATH"
echo "  Backend: $ENV_PATH"
echo ""
echo "Next steps:"
echo "  1. Build iOS app in Xcode to test login flow"
echo "  2. Deploy backend to Render with Auth0 env vars"
echo "  3. Test full auth flow on device"
echo ""
echo "Auth0 Dashboard: https://manage.auth0.com/dashboard"
echo "  Domain: $AUTH0_DOMAIN"
echo "  Audience: $AUTH0_AUDIENCE"
echo "  Client ID: $AUTH0_CLIENT_ID"
echo ""
