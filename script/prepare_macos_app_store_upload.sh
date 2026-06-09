#!/usr/bin/env bash
# Sign dist/Revoxa.app for Mac App Store and build an uploadable .pkg.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/Revoxa.app"
PKG_PATH="$ROOT_DIR/dist/Revoxa-macOS.pkg"
ENTITLEMENTS_FILE="$ROOT_DIR/Configurations/Revoxa-macOS/Revoxa-macOS.entitlements"
BUNDLE_ID="com.revoxa.app"
RESOURCE_BUNDLE_ID="$BUNDLE_ID.resources"
SIGN_IDENTITY="${REVOXA_SIGN_IDENTITY:-}"

usage() {
  cat <<EOF
usage: REVOXA_SIGN_IDENTITY='Apple Distribution: Name (TEAMID)' $0

Prepares dist/Revoxa.app for Mac App Store / TestFlight upload:
  1. Ensures a release App Store sandbox build exists
  2. Signs the app with Apple Distribution
  3. Creates dist/Revoxa-macOS.pkg for Transporter

List signing identities:
  security find-identity -v -p codesigning | grep 'Apple Distribution'

Installer package signing (optional override):
  Installer certificates may not appear in the codesigning identity list.
  If automatic discovery fails, copy the exact certificate name from Keychain Access:
  export REVOXA_INSTALLER_IDENTITY='3rd Party Mac Developer Installer: Name (TEAMID)'

Upload:
  Open Transporter → add dist/Revoxa-macOS.pkg → Deliver
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -z "$SIGN_IDENTITY" ]]; then
  echo "error: REVOXA_SIGN_IDENTITY is not set." >&2
  echo "" >&2
  echo "Example:" >&2
  echo "  export REVOXA_SIGN_IDENTITY='Apple Distribution: Your Name (TEAMID)'" >&2
  echo "  $0" >&2
  echo "" >&2
  security find-identity -v -p codesigning | grep -E 'Apple Distribution|Mac Installer Distribution|3rd Party Mac Developer' >&2 || true
  exit 2
fi

resolve_installer_identity() {
  if [[ -n "${REVOXA_INSTALLER_IDENTITY:-}" ]]; then
    echo "$REVOXA_INSTALLER_IDENTITY"
    return 0
  fi

  security find-identity -v -p codesigning \
    | grep -iE 'Mac Installer Distribution|3rd Party Mac Developer Installer' \
    | head -1 \
    | cut -d'"' -f2
}

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "Building release Mac App Store app bundle..." >&2
  "$ROOT_DIR/script/package_app.sh" --release --app-store >/dev/null
fi

"$ROOT_DIR/script/verify_mac_app_store_entitlements.sh" "$APP_BUNDLE"

if ! command -v codesign >/dev/null 2>&1; then
  echo "error: codesign not found" >&2
  exit 1
fi

RESOURCE_BUNDLE="$APP_BUNDLE/Contents/MacOS/Revoxa_Revoxa.bundle"
sign_path() {
  local target="$1"
  local identifier="${2:-$BUNDLE_ID}"
  codesign --force --options runtime --timestamp \
    --sign "$SIGN_IDENTITY" \
    --identifier "$identifier" \
    "$target"
}

echo "Signing resource bundle (if present)..." >&2
if [[ -d "$RESOURCE_BUNDLE" ]]; then
  sign_path "$RESOURCE_BUNDLE" "$RESOURCE_BUNDLE_ID"
fi

echo "Signing app binary..." >&2
sign_path "$APP_BUNDLE/Contents/MacOS/Revoxa"

echo "Signing app bundle with entitlements..." >&2
codesign --force --deep --options runtime --timestamp \
  --sign "$SIGN_IDENTITY" \
  --identifier "$BUNDLE_ID" \
  --entitlements "$ENTITLEMENTS_FILE" \
  "$APP_BUNDLE"

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE" >&2

if ! command -v productbuild >/dev/null 2>&1; then
  echo "error: productbuild not found (install Xcode command line tools)" >&2
  exit 1
fi

INSTALLER_IDENTITY="$(resolve_installer_identity)"
if [[ -z "$INSTALLER_IDENTITY" ]]; then
  echo "error: Mac Installer Distribution certificate not found." >&2
  echo "" >&2
  echo "Create one in Xcode → Settings → Accounts → Manage Certificates → + → Mac Installer Distribution" >&2
  echo "Then re-run this script, or set REVOXA_INSTALLER_IDENTITY explicitly from Keychain Access." >&2
  echo "Example:" >&2
  echo "  export REVOXA_INSTALLER_IDENTITY='3rd Party Mac Developer Installer: Your Name (TEAMID)'" >&2
  echo "" >&2
  echo "Note: installer certificates do not always appear in 'security find-identity -p codesigning' output." >&2
  echo "" >&2
  security find-identity -v -p codesigning | grep -iE 'Installer|Distribution' >&2 || true
  exit 3
fi

echo "Using installer identity: $INSTALLER_IDENTITY" >&2
rm -f "$PKG_PATH"

echo "Creating installer package..." >&2
productbuild \
  --component "$APP_BUNDLE" /Applications \
  --sign "$INSTALLER_IDENTITY" \
  "$PKG_PATH"

echo ""
echo "Ready for upload:"
echo "  $PKG_PATH"
echo ""
echo "Next steps:"
echo "  1. Open Transporter (Mac App Store)"
echo "  2. Add dist/Revoxa-macOS.pkg"
echo "  3. Deliver"
echo "  4. App Store Connect → Revoxa → TestFlight → macOS"
