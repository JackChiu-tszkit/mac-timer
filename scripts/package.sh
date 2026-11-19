#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

xcodebuild \
  -project MacTimer.xcodeproj \
  -scheme Timer \
  -configuration Debug \
  -destination "platform=macOS" \
  -derivedDataPath build/Debug \
  test

xcodebuild \
  -project MacTimer.xcodeproj \
  -scheme Timer \
  -configuration Release \
  -destination "platform=macOS" \
  -derivedDataPath build/Release \
  build

APP="build/Release/Build/Products/Release/Timer.app"
STAGE="build/dmg-root"
rm -rf "$STAGE"
mkdir -p "$STAGE" dist
cp -R "$APP" "$STAGE/Timer.app"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Timer" -srcfolder "$STAGE" -ov -format UDZO "dist/Timer.dmg"
echo "Created dist/Timer.dmg"
