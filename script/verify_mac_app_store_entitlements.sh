#!/usr/bin/env bash
# Validates Mac App Store sandbox entitlements for Revoxa.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENTITLEMENTS_FILE="$ROOT_DIR/Configurations/Revoxa-macOS/Revoxa-macOS.entitlements"
APP_BUNDLE="${1:-$ROOT_DIR/dist/Revoxa.app}"

fail() {
  echo "mas-verify: FAIL — $*" >&2
  exit 1
}

pass() {
  echo "mas-verify: OK — $*"
}

read_entitlement() {
  local key="$1"
  /usr/libexec/PlistBuddy -c "Print :$key" "$ENTITLEMENTS_FILE" 2>/dev/null || true
}

[[ -f "$ENTITLEMENTS_FILE" ]] || fail "missing entitlements file: $ENTITLEMENTS_FILE"

for key in \
  com.apple.security.app-sandbox \
  com.apple.security.network.client \
  com.apple.security.files.user-selected.read-write
do
  value="$(read_entitlement "$key")"
  [[ "$value" == "true" ]] || fail "expected $key = true, got: ${value:-<missing>}"
done

pass "entitlements plist has required Mac App Store keys"

if [[ -d "$APP_BUNDLE" ]]; then
  if ! command -v codesign >/dev/null 2>&1; then
    echo "mas-verify: skip — codesign not available; bundle not checked" >&2
    exit 0
  fi

  embedded="$(codesign -d --entitlements :- "$APP_BUNDLE" 2>/dev/null || true)"
  [[ -n "$embedded" ]] || fail "app bundle is not signed or has no embedded entitlements: $APP_BUNDLE"

  for key in \
    com.apple.security.app-sandbox \
    com.apple.security.network.client \
    com.apple.security.files.user-selected.read-write
  do
    echo "$embedded" | grep -q "<key>$key</key>" \
      || fail "signed bundle missing entitlement: $key"
  done

  pass "signed bundle embeds sandbox entitlements ($APP_BUNDLE)"
fi

echo "mas-verify: all checks passed"
