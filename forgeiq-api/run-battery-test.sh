#!/bin/bash
# ForgeIQ Battery Test Runner
# Validates system readiness and runs 100-scenario battery test

set -e

echo "🔧 ForgeIQ Battery Test Pre-Flight"
echo ""

# Check Node.js
if ! command -v node &> /dev/null; then
  echo "❌ Node.js not found. Install Node.js 20 LTS."
  exit 1
fi
echo "✓ Node.js: $(node --version)"

# Check if backend directory exists
if [ ! -f "package.json" ]; then
  echo "❌ Run this script from forgeiq-api directory"
  exit 1
fi
echo "✓ In forgeiq-api directory"

# Check environment variables
REQUIRED_VARS=(
  "AUTH0_DOMAIN"
  "AUTH0_CLIENT_ID"
  "AUTH0_CLIENT_SECRET"
  "AUTH0_AUDIENCE"
  "BATTERY_TEST_PASSWORD"
)

MISSING=()
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    MISSING+=("$var")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "❌ Missing environment variables:"
  for var in "${MISSING[@]}"; do
    echo "   - $var"
  done
  echo ""
  echo "Set them in .env or export them:"
  echo "  export AUTH0_DOMAIN=your-tenant.auth0.com"
  echo "  export AUTH0_CLIENT_ID=your-client-id"
  echo "  export AUTH0_CLIENT_SECRET=your-client-secret"
  echo "  export AUTH0_AUDIENCE=your-api-identifier"
  echo "  export BATTERY_TEST_PASSWORD=BatteryTest123!"
  exit 1
fi
echo "✓ All required env vars present"

# Check if backend is running
if ! curl -s http://localhost:3001/health > /dev/null 2>&1; then
  echo "⚠️  Backend not running at http://localhost:3001"
  echo ""
  echo "Start it first:"
  echo "  npm start"
  echo ""
  read -p "Start backend now? (y/n) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    npm start &
    BACKEND_PID=$!
    echo "⏳ Waiting for backend to start..."
    sleep 5
    if ! curl -s http://localhost:3001/health > /dev/null 2>&1; then
      echo "❌ Backend failed to start"
      kill $BACKEND_PID 2>/dev/null || true
      exit 1
    fi
    echo "✓ Backend started"
  else
    echo "❌ Backend must be running to execute battery test"
    exit 1
  fi
else
  echo "✓ Backend responding at http://localhost:3001"
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
  echo "📦 Installing dependencies..."
  npm install --silent
fi

# Run battery test
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

node battery-test.js

EXIT_CODE=$?

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ BATTERY TEST PASSED"
  echo ""
  echo "Next steps:"
  echo "  1. Review BATTERY_TEST_RESULTS.md"
  echo "  2. Update CLAUDE.md with sigma level achieved"
  echo "  3. Proceed with Phase 1 deployment"
else
  echo "⚠️  BATTERY TEST FAILED"
  echo ""
  echo "Next steps:"
  echo "  1. Review BATTERY_TEST_RESULTS.md for failure details"
  echo "  2. Fix root causes per recommendations"
  echo "  3. Re-run: ./run-battery-test.sh"
  echo "  4. Do NOT deploy until pass rate ≥ 99.5%"
fi

echo ""

# Cleanup background backend if we started it
if [ ! -z "$BACKEND_PID" ]; then
  echo "🛑 Stopping test backend..."
  kill $BACKEND_PID 2>/dev/null || true
fi

exit $EXIT_CODE
