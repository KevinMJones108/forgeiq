#!/bin/bash
# ForgeIQ — Build and Deploy to Connected iPhone
# Usage: ./test-on-device.sh
# Requires: Xcode 16+, iPhone connected via USB, codesigning configured

set -e  # Exit on any error

echo "🔨 ForgeIQ iPhone Deployment Script"
echo "===================================="

# Configuration
PROJECT_DIR="/Users/kevinmarlesjones/qbo/forgeiq/forgeiq-api"
XCODE_PROJECT="$PROJECT_DIR/ForgeIQ.xcodeproj"
SCHEME="ForgeIQ"
CONFIGURATION="Debug"
DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"

# Step 1: Verify iPhone connected
echo ""
echo "📱 Step 1/5: Checking for connected iPhone..."
DEVICE_COUNT=$(xcrun xctrace list devices 2>&1 | grep -c "iPhone" || true)

if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "❌ ERROR: No iPhone detected"
    echo "   → Connect iPhone via USB cable"
    echo "   → Trust this computer on iPhone"
    echo "   → Run: xcrun xctrace list devices"
    exit 1
fi

DEVICE_NAME=$(xcrun xctrace list devices 2>&1 | grep "iPhone" | head -n 1 | sed 's/ (.*//')
echo "✅ Found device: $DEVICE_NAME"

# Step 2: Clean build folder
echo ""
echo "🧹 Step 2/5: Cleaning build folder..."
rm -rf "$DERIVED_DATA_PATH/ForgeIQ-"*
echo "✅ Clean complete"

# Step 3: Build for device
echo ""
echo "🔧 Step 3/5: Building ForgeIQ for iPhone..."
echo "   Configuration: $CONFIGURATION"
echo "   Scheme: $SCHEME"

xcodebuild \
    -project "$XCODE_PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "generic/platform=iOS" \
    -derivedDataPath "$DERIVED_DATA_PATH/ForgeIQ-Build" \
    clean build \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="" \
    | xcpretty || xcodebuild \
        -project "$XCODE_PROJECT" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -destination "generic/platform=iOS" \
        clean build

if [ $? -ne 0 ]; then
    echo "❌ BUILD FAILED"
    echo "   Check Xcode signing settings:"
    echo "   1. Open ForgeIQ.xcodeproj in Xcode"
    echo "   2. Select ForgeIQ target → Signing & Capabilities"
    echo "   3. Verify Team selected and Bundle ID correct"
    exit 1
fi

echo "✅ Build succeeded"

# Step 4: Install on device
echo ""
echo "📲 Step 4/5: Installing on $DEVICE_NAME..."

# Find the .app bundle
APP_PATH=$(find "$DERIVED_DATA_PATH/ForgeIQ-Build" -name "ForgeIQ.app" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "❌ ERROR: Could not find ForgeIQ.app in build output"
    exit 1
fi

echo "   App bundle: $APP_PATH"

# Install using xcrun devicectl (iOS 17+) or fallback to older method
if command -v devicectl &> /dev/null; then
    xcrun devicectl device install app --device "$DEVICE_NAME" "$APP_PATH"
else
    # Fallback for older Xcode versions
    xcrun simctl install booted "$APP_PATH" 2>/dev/null || \
    ios-deploy --bundle "$APP_PATH" --no-wifi
fi

if [ $? -ne 0 ]; then
    echo "❌ INSTALL FAILED"
    echo "   → Verify iPhone is unlocked"
    echo "   → Check Developer Mode enabled (Settings → Privacy & Security → Developer Mode)"
    exit 1
fi

echo "✅ App installed successfully"

# Step 5: Launch app
echo ""
echo "🚀 Step 5/5: Launching ForgeIQ on device..."

BUNDLE_ID="ai.alviz.forgeiq"

if command -v devicectl &> /dev/null; then
    xcrun devicectl device process launch --device "$DEVICE_NAME" "$BUNDLE_ID" --console
else
    ios-deploy --bundle_id "$BUNDLE_ID" --no-wifi --justlaunch
fi

echo ""
echo "✅ DEPLOYMENT COMPLETE"
echo ""
echo "📋 Next Steps:"
echo "   1. iPhone should show ForgeIQ app launched"
echo "   2. Allow microphone + speech recognition permissions"
echo "   3. Follow IPHONE_TEST_PROTOCOL.md test cases"
echo "   4. Report results in Test Execution Log"
echo ""
echo "💡 Tips:"
echo "   • Xcode → Window → Devices → [iPhone] → View Device Logs (real-time console)"
echo "   • If app crashes: check console for error messages"
echo "   • If permissions denied: Settings → Privacy → Microphone/Speech Recognition"
echo ""
echo "🐛 Troubleshooting:"
echo "   • Build errors: open Xcode GUI and check signing settings"
echo "   • Install errors: verify Developer Mode ON (iOS 16+)"
echo "   • Launch errors: check iPhone is unlocked"
echo ""
