#!/bin/bash
# Generate AppIcon.icns for GestureTabs from tools/make-icon.swift.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="/tmp/gesturetabs-icon-1024.png"
SET="$ROOT/AppIcon.iconset"

echo "==> Rendering 1024px icon"
swift "$ROOT/tools/make-icon.swift" "$SRC"

echo "==> Building iconset"
rm -rf "$SET"
mkdir -p "$SET"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$SRC" --out "$SET/icon_${size}x${size}.png" >/dev/null
    d=$((size * 2))
    sips -z "$d" "$d" "$SRC" --out "$SET/icon_${size}x${size}@2x.png" >/dev/null
done

echo "==> Packing AppIcon.icns"
iconutil -c icns "$SET" -o "$ROOT/AppIcon.icns"
rm -rf "$SET"

echo "==> Done: $ROOT/AppIcon.icns"
