#!/usr/bin/env bash
# Copy a built Revoxa.app into /Applications and refresh Launch Services.
set -euo pipefail

APP_NAME="Revoxa"
INSTALL_DIR="/Applications"
TARGET_APP="$INSTALL_DIR/$APP_NAME.app"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_APP=""
STOP_RUNNING=true
REFRESH_FINDER=false
SKIP_REGISTER=false
SKIP_DOCK_RESTART=false

usage() {
  cat <<EOF
usage: $0 [options] [path/to/Revoxa.app]

Copy the given bundle (default: dist/Revoxa.app) to $TARGET_APP.

Options:
  --refresh-finder   Also restart Finder after sync
  --skip-register    Skip lsregister
  --skip-dock        Skip Dock restart
  --no-pkill         Do not quit a running $APP_NAME first
  -h, --help         Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --refresh-finder)
      REFRESH_FINDER=true
      shift
      ;;
    --skip-register)
      SKIP_REGISTER=true
      shift
      ;;
    --skip-dock)
      SKIP_DOCK_RESTART=true
      shift
      ;;
    --no-pkill)
      STOP_RUNNING=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "$SOURCE_APP" ]]; then
        echo "error: multiple app bundle paths provided" >&2
        exit 2
      fi
      SOURCE_APP="$1"
      shift
      ;;
  esac
done

if [[ -z "$SOURCE_APP" ]]; then
  SOURCE_APP="$ROOT_DIR/dist/$APP_NAME.app"
fi

if [[ ! -d "$SOURCE_APP" ]]; then
  echo "error: app bundle not found: $SOURCE_APP" >&2
  exit 1
fi

if [[ ! -w "$INSTALL_DIR" ]]; then
  echo "error: cannot write to $INSTALL_DIR (try: sudo $0)" >&2
  exit 1
fi

if [[ "$STOP_RUNNING" == true ]]; then
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
  sleep 0.3
fi

echo "Syncing $SOURCE_APP → $TARGET_APP ..." >&2
rm -rf "$TARGET_APP"
ditto "$SOURCE_APP" "$TARGET_APP"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "$TARGET_APP" >/dev/null 2>&1 || true
fi

if [[ "$SKIP_REGISTER" != true ]]; then
  LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"
  if [[ -x "$LSREGISTER" ]]; then
    "$LSREGISTER" -f -R -trusted "$TARGET_APP" >/dev/null 2>&1 || true
  fi
  touch "$TARGET_APP"
fi

if [[ "$SKIP_DOCK_RESTART" != true ]]; then
  killall Dock >/dev/null 2>&1 || true
fi

if [[ "$REFRESH_FINDER" == true ]]; then
  killall Finder >/dev/null 2>&1 || true
fi

echo "$TARGET_APP"
