#!/bin/sh
set -eu
cd "$(dirname "$0")"
swift build -c release
app="$(pwd)/FreeDEdit.app"
mkdir -p "$app/Contents/MacOS"
cp .build/release/FreeDEdit "$app/Contents/MacOS/FreeDEdit"
cp Info.plist "$app/Contents/Info.plist"
codesign --force --deep --sign - "$app"
echo "Built $app"
