#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Revoxa"
BUNDLE_ID="com.revoxa.app"
APPLICATIONS_APP="/Applications/$APP_NAME.app"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_ARGS=(--configuration debug)
SKIP_APPLICATIONS_SYNC=false
SYNC_ARGS=()
MODE="run"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release|release)
      PACKAGE_ARGS=(--configuration release)
      shift
      ;;
    --skip-applications-sync)
      SKIP_APPLICATIONS_SYNC=true
      shift
      ;;
    --refresh-finder)
      SYNC_ARGS+=(--refresh-finder)
      shift
      ;;
    --skip-register)
      SYNC_ARGS+=(--skip-register)
      shift
      ;;
    --skip-dock)
      SYNC_ARGS+=(--skip-dock)
      shift
      ;;
    --debug|debug|--logs|logs|--telemetry|telemetry|--verify|verify|--package-only|package-only|-h|--help|run)
      MODE="${1#--}"
      [[ "$1" == "debug" || "$1" == "release" ]] && MODE="$1"
      [[ "$MODE" == "help" ]] && MODE="--help"
      shift
      break
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

APP_BUNDLE="$("$ROOT_DIR/script/package_app.sh" "${PACKAGE_ARGS[@]}" | tail -1)"

if [[ "$SKIP_APPLICATIONS_SYNC" != true ]]; then
  SYNC_CMD=("$ROOT_DIR/script/sync_applications.sh" --no-pkill "$APP_BUNDLE")
  if [[ ${#SYNC_ARGS[@]} -gt 0 ]]; then
    SYNC_CMD=("$ROOT_DIR/script/sync_applications.sh" "${SYNC_ARGS[@]}" --no-pkill "$APP_BUNDLE")
  fi
  if "${SYNC_CMD[@]}" >/dev/null; then
    echo "Updated: $APPLICATIONS_APP" >&2
  else
    echo "warning: could not update $APPLICATIONS_APP (check write permission)" >&2
  fi
fi

open_app() {
  local launch_target="$APP_BUNDLE"
  if [[ -d "$APPLICATIONS_APP" ]]; then
    launch_target="$APPLICATIONS_APP"
  fi
  /usr/bin/open -n "$launch_target"
}

case "$MODE" in
  run|"")
    open_app
    ;;
  debug)
    if [[ -d "$APPLICATIONS_APP" ]]; then
      lldb -- "$APPLICATIONS_APP/Contents/MacOS/$APP_NAME"
    else
      lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    fi
    ;;
  logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  package-only)
    echo "Packaged: $APP_BUNDLE"
    if [[ -d "$APPLICATIONS_APP" ]]; then
      echo "Applications: $APPLICATIONS_APP"
    fi
    ;;
  -h|--help)
    cat <<EOF
usage: $0 [options] [run|--debug|--logs|--telemetry|--verify|--package-only]

Build dist/Revoxa.app, sync to /Applications/Revoxa.app, and optionally launch it.

  $0                        Debug build, update Applications, open app
  $0 --release              Release build, update Applications, open app
  $0 --package-only         Build + sync only (no open)
  $0 --skip-applications-sync
                            Do not copy to /Applications
  $0 --verify               Build, sync, open, confirm process is running

Full Release install: ./script/install-local.sh
EOF
    ;;
  *)
    echo "usage: $0 [--release] [--skip-applications-sync] [run|--package-only|...]" >&2
    exit 2
    ;;
esac
