#!/bin/bash

# InfoDigest iOS App Build Script
# This script will build and deploy the app to your device

echo "🚀 Starting InfoDigest iOS App Build Process..."

PROJECT_PATH="/Users/huiminzhang/Bspace/project/1_iphone_app/InfoDigest"
PROJECT_FILE="$PROJECT_PATH/InfoDigest.xcodeproj"
SCHEME="InfoDigest"

# Step 1: Clean build folder
echo "🧹 Cleaning build folder..."
cd "$PROJECT_PATH"
rm -rf build/
rm -rf ~/Library/Developer/Xcode/DerivedData/InfoDigest-*/

# Step 2: List all Swift files that should be in the project
echo "📝 Swift files in project:"
find InfoDigest -name "*.swift" -not -path "*/build/*" | sort

# Step 3: Build the project
echo "🔨 Building project..."
xcodebuild -project "$PROJECT_FILE" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -sdk iphoneos \
  -destination 'platform=iOS,name=iPhone' \
  clean build 2>&1 | tee build.log

BUILD_STATUS=${PIPESTATUS[0]}

if [ $BUILD_STATUS -eq 0 ]; then
  echo "✅ Build successful!"

  # Step 4: Get the app path
  APP_PATH=$(find build/Build/Products/Debug-iphoneos/ -name "*.app" | head -1)

  if [ -n "$APP_PATH" ]; then
    echo "📦 App built at: $APP_PATH"

    # Step 5: Install to device (requires device to be connected)
    echo "📱 Checking for connected devices..."
    DEVICES=$(xcrun xctrace list devices 2>&1 | grep "iPhone" | grep -v "Simulator")

    if [ -n "$DEVICES" ]; then
      echo "Found devices:"
      echo "$DEVICES"

      # Get the first device ID
      DEVICE_ID=$(echo "$DEVICES" | head -1 | sed 's/.*(\(.*\)).*/\1/')

      if [ -n "$DEVICE_ID" ]; then
        echo "🚀 Installing to device: $DEVICE_ID"
        xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"
      fi
    else
      echo "⚠️  No iPhone device found. Please connect your device."
      echo "⚠️  You can also install the app manually from Xcode."
    fi
  else
    echo "❌ Could not find built app"
  fi
else
  echo "❌ Build failed. Check build.log for details."
  tail -50 build.log
fi

echo ""
echo "📋 Summary:"
echo "Project: $PROJECT_FILE"
echo "Scheme: $SCHEME"
echo "Build Status: $([ $BUILD_STATUS -eq 0 ] && echo '✅ Success' || echo '❌ Failed')"

echo ""
echo "💡 Next steps:"
echo "1. If build succeeded, open Xcode:"
echo "   open '$PROJECT_FILE'"
echo ""
echo "2. Select your device from the top menu"
echo ""
echo "3. Click the Run button (▶) or press Cmd+R"
