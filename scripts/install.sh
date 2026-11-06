#!/bin/zsh
# Build a Release copy of SelfCaffeinate and install it to /Applications.
#
# Usage: scripts/install.sh [--no-open]
#
# Run the installed copy (not the Xcode build) before enabling "Launch at Login"
# from the menu, so the login item points at a stable path.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME=SelfCaffeinate
BUILD_DIR=build
SRC="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
DEST="/Applications/$APP_NAME.app"
OPEN_AFTER=1
[[ "${1:-}" == "--no-open" ]] && OPEN_AFTER=0

echo "Building Release…"
xcodebuild -scheme "$APP_NAME" -configuration Release -derivedDataPath "$BUILD_DIR" -quiet build

if pgrep -xq "$APP_NAME"; then
  echo "Quitting running copy…"
  osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || pkill -x "$APP_NAME" || true
  for _ in {1..20}; do pgrep -xq "$APP_NAME" || break; sleep 0.25; done
fi

rm -rf "$DEST"
ditto "$SRC" "$DEST"
echo "Installed $DEST"

if (( OPEN_AFTER )); then
  open "$DEST"
  echo "Launched. Use the cup menu → Launch at Login to start it automatically."
fi
