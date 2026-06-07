#!/usr/bin/env bash
# Release build → /Applications with Launch Services + safe Dock/Finder refresh.
set -euo pipefail

APP_NAME="Revoxa"
TARGET_APP="/Applications/$APP_NAME.app"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REFRESH_FINDER=false
SKIP_REGISTER=false
SKIP_DOCK_RESTART=false

usage() {
  cat <<EOF
usage: $0 [options]

Build dist/Revoxa.app (Release), replace $TARGET_APP, refresh Launch Services,
and optionally restart Dock/Finder so system surfaces (Stage Manager, Launchpad)
pick up the new icon.

Options:
  --refresh-finder   Also restart Finder after install (Dock always restarts)
  --skip-register    Skip lsregister
  --skip-dock        Skip Dock restart
  -h, --help         Show this help

Recommended after install: quit Revoxa, open from /Applications only (not Xcode).
EOF
}

SYNC_ARGS=()
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
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$REFRESH_FINDER" == true ]]; then
  SYNC_ARGS+=(--refresh-finder)
fi
if [[ "$SKIP_REGISTER" == true ]]; then
  SYNC_ARGS+=(--skip-register)
fi
if [[ "$SKIP_DOCK_RESTART" == true ]]; then
  SYNC_ARGS+=(--skip-dock)
fi

echo "Stopping $APP_NAME if running..." >&2
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
sleep 0.5

APP_BUNDLE="$("$ROOT_DIR/script/package_app.sh" --configuration release | tail -1)"
if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "error: expected app bundle at $APP_BUNDLE" >&2
  exit 1
fi

"$ROOT_DIR/script/verify_app_bundle.sh" "$APP_BUNDLE"

if [[ ${#SYNC_ARGS[@]} -gt 0 ]]; then
  "$ROOT_DIR/script/sync_applications.sh" "${SYNC_ARGS[@]}" --no-pkill "$APP_BUNDLE" >/dev/null
else
  "$ROOT_DIR/script/sync_applications.sh" --no-pkill "$APP_BUNDLE" >/dev/null
fi

echo ""
echo "Installed: $TARGET_APP"
echo "Open Revoxa from Finder → Uygulamalar (not from Xcode DerivedData)."
echo "If Stage Manager still shows an empty icon, see README → Icon / Stage Manager sorun giderme."
