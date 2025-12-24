#!/bin/bash

# harden_agent.sh - Elevate NetPulse to Root LaunchDaemon
# Must be run with sudo

set -e

# If an argument is passed, use it as APP_PATH, otherwise use the directory of the script
if [ -n "$1" ]; then
  APP_PATH="$1"
else
  # Default fallback if run manually from repo
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  APP_PATH="$SCRIPT_DIR/NetPulse.app"
fi

BINARY_SOURCE="$APP_PATH/Contents/MacOS/NetPulse"
INSTALL_DIR="/Library/Application Support/NetPulse"
INSTALL_BINARY="$INSTALL_DIR/NetPulse"
PLIST_LABEL="id.emiro.netpulse"
PLIST_SOURCE="/tmp/$PLIST_LABEL.plist"
PLIST_DEST="/Library/LaunchDaemons/$PLIST_LABEL.plist"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run with sudo: sudo ./harden_agent.sh"
  exit 1
fi

echo "🛡️ Hardening NetPulse Agent..."

# 1. Create secure directory
mkdir -p "$INSTALL_DIR"
chmod 755 "$INSTALL_DIR"

# 2. Copy binary
echo "📦 Source Binary: $BINARY_SOURCE"
echo "📦 Destination: $INSTALL_BINARY"

if [ ! -f "$BINARY_SOURCE" ]; then
    echo "❌ Error: Source binary not found at $BINARY_SOURCE"
    # Try a desperate search just in case
    echo "🔍 Searching for binary in $APP_PATH..."
    find "$APP_PATH" -name "NetPulse" -type f
    exit 1
fi

echo "📦 Copying binary to secure location..."
cp -f "$BINARY_SOURCE" "$INSTALL_BINARY"
chown root:wheel "$INSTALL_BINARY"
chmod 755 "$INSTALL_BINARY"
echo "✅ Binary copied and permissions set."

# 3. Create Root LaunchDaemon Plist
echo "📝 Generating Root LaunchDaemon plist..."
cat <<EOF > "$PLIST_SOURCE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_BINARY</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>StandardErrorPath</key>
    <string>/var/log/netpulse.log</string>
</dict>
</plist>
EOF

mv "$PLIST_SOURCE" "$PLIST_DEST"
chown root:wheel "$PLIST_DEST"
chmod 644 "$PLIST_DEST"

# 4. Remove User LaunchAgent to avoid conflict
USER_PLIST="/Users/mochammad.emir/Library/LaunchAgents/$PLIST_LABEL.plist"
if [ -f "$USER_PLIST" ]; then
    echo "🧹 Removing User-level LaunchAgent to avoid conflicts..."
    # We don't use sudo for user domain bootout, but since we are root here...
    # It's better to let the app handle its own cleanup or just rm the file.
    rm -f "$USER_PLIST"
fi

# 5. Load the Daemon
echo "🚀 Loading System LaunchDaemon..."
launchctl unload "$PLIST_DEST" 2>/dev/null || true
launchctl load -w "$PLIST_DEST"

echo "✅ NetPulse has been Hardened! It is now running as a System Root Daemon."
echo "🛡️ Tamper Resistance is ACTIVE. Unprivileged users cannot stop this process."
