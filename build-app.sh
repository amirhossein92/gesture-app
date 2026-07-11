#!/bin/bash
# Build GestureTabs.app: a menu-bar agent bundle containing both the
# gesture-control (UI) and gesture-app (service) binaries.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/GestureTabs.app"
BIN="$ROOT/.build/release"

echo "==> Building release binaries"
swift build -c release

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$ROOT/Info.plist"        "$APP/Contents/Info.plist"
cp "$BIN/gesture-control"    "$APP/Contents/MacOS/gesture-control"
cp "$BIN/gesture-app"        "$APP/Contents/MacOS/gesture-app"

if [ -f "$ROOT/AppIcon.icns" ]; then
    cp "$ROOT/AppIcon.icns"  "$APP/Contents/Resources/AppIcon.icns"
else
    echo "    (no AppIcon.icns — run ./make-icon.sh to generate one)"
fi

echo "==> Ad-hoc code signing"
# Sign the nested service first, then the app, so the bundle stays valid.
codesign --force --sign - "$APP/Contents/MacOS/gesture-app"
codesign --force --sign - "$APP/Contents/MacOS/gesture-control"
codesign --force --sign - "$APP"

echo "==> Done: $APP"
echo "    Launch with:  open \"$APP\""
