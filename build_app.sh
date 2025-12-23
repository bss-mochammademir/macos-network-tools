#!/bin/bash

# Configuration
APP_NAME="NetPulse"
VERSION="1.1"
BUNDLE_ID="com.emir.netpulse"

echo "🚀 Building $APP_NAME..."

# 1. Kill any running instances to avoid locking
killall "$APP_NAME" 2>/dev/null || true

# 2. Build in Release mode
if ! swift build -c release; then
    echo "❌ Build failed."
    exit 1
fi

# 3. Setup App Structure
APP_BUNDLE="$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# 4. Copy Binary
BINARY_PATH=$(swift build -c release --show-bin-path)/$APP_NAME
if [ -f "$BINARY_PATH" ]; then
    cp "$BINARY_PATH" "$MACOS/"
else
    echo "❌ Binary not found."
    exit 1
fi

# 5. Copy Icon
if [ -f "NetPulse.icns" ]; then
    cp "NetPulse.icns" "$RESOURCES/"
fi

# 6. Create Info.plist
cat <<EOF > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 7. Ad-hoc Code Signing (Forces macOS to re-read the bundle metadata/icon)
echo "🔐 Cleaning metadata and signing app..."
xattr -cr "$APP_BUNDLE"
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✅ Done! NetPulse.app is ready."
