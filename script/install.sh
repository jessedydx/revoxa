#!/usr/bin/env bash
# Build a Release Revoxa.app and install it to /Applications for local use.
set -euo pipefail

APP_NAME="Revoxa"
INSTALL_DIR="/Applications"
TARGET_APP="$INSTALL_DIR/$APP_NAME.app"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=false
SKIP_REGISTER=false

usage() {
  cat <<EOF
usage: $0 [options]

Build dist/Revoxa.app (Release) and copy it to $TARGET_APP.

Options:
  --dry-run          Build only; do not copy to /Applications
  --skip-register    Skip Launch Services refresh after install
  -h, --help         Show this help

Examples:
  $0
  $0 --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --skip-register)
      SKIP_REGISTER=true
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

if [[ "$DRY_RUN" == true ]]; then
  APP_BUNDLE="$("$ROOT_DIR/script/package_app.sh" --configuration release | tail -1)"
  if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "error: expected app bundle at $APP_BUNDLE" >&2
    exit 1
  fi
  echo "Dry run: built $APP_BUNDLE (not installed)."
  exit 0
fi

INSTALL_ARGS=()
if [[ "$SKIP_REGISTER" == true ]]; then
  INSTALL_ARGS+=(--skip-register)
fi
exec "$ROOT_DIR/script/install-local.sh" "${INSTALL_ARGS[@]}"
