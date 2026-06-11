#!/usr/bin/env bash
# Legacy manual packager. Prefer prepare_macos_xcode_app_store_upload.sh for
# macOS TestFlight / Mac App Store uploads.
# Sign dist/Revoxa.app for Mac App Store and build an uploadable .pkg.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/Revoxa.app"
PKG_PATH="$ROOT_DIR/dist/Revoxa-macOS.pkg"
ENTITLEMENTS_FILE="$ROOT_DIR/Configurations/Revoxa-macOS/Revoxa-macOS.entitlements"
EMBEDDED_PROFILE="$APP_BUNDLE/Contents/embedded.provisionprofile"
SIGNING_ENTITLEMENTS="$(mktemp "${TMPDIR:-/tmp}/revoxa-signing-entitlements-XXXXXX.plist")"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/revoxa-productbuild-XXXXXX")"
EXPANDED_PKG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/revoxa-expanded-pkg-XXXXXX")"
INSTALLER_CERT_PEM="$(mktemp "${TMPDIR:-/tmp}/revoxa-installer-cert-XXXXXX.pem")"
STAGED_APP="$STAGING_DIR/Revoxa.app"
BUNDLE_ID="com.revoxa.app"
RESOURCE_BUNDLE_ID="$BUNDLE_ID.resources"
SIGN_IDENTITY="${REVOXA_SIGN_IDENTITY:-}"
PROVISIONING_PROFILE="${REVOXA_PROVISIONING_PROFILE:-}"
TEAM_ID="${REVOXA_TEAM_ID:-}"

cleanup() {
  rm -f "$SIGNING_ENTITLEMENTS"
  rm -f "$INSTALLER_CERT_PEM"
  rm -rf "$STAGING_DIR"
  rm -rf "$EXPANDED_PKG_DIR"
}
trap cleanup EXIT

clean_bundle_metadata() {
  local target="$1"

  if command -v xattr >/dev/null 2>&1; then
    xattr -cr "$target" >/dev/null 2>&1 || true
  fi

  find "$target" \( -name '._*' -o -name '.DS_Store' \) -print -delete
}

usage() {
  cat <<EOF
usage: REVOXA_SIGN_IDENTITY='Apple Distribution: Name (TEAMID)' $0

Prepares dist/Revoxa.app for Mac App Store / TestFlight upload:
  1. Ensures a release App Store sandbox build exists
  2. Embeds a Mac App Store provisioning profile
  3. Signs the app with an App Store distribution identity
  4. Creates dist/Revoxa-macOS.pkg for Transporter

List signing identities:
  security find-identity -v -p codesigning | grep '3rd Party Mac Developer Application'
  security find-identity -v -p codesigning | grep 'Apple Distribution'

Installer package signing (optional override):
  Installer certificates may not appear in the codesigning identity list.
  If automatic discovery fails, copy the exact certificate name from Keychain Access:
  export REVOXA_INSTALLER_IDENTITY='3rd Party Mac Developer Installer: Name (TEAMID)'

Provisioning profile:
  export REVOXA_PROVISIONING_PROFILE='/path/to/Mac_App_Store_com.revoxa.app.provisionprofile'
  export REVOXA_TEAM_ID='TEAMID' # optional; inferred from REVOXA_SIGN_IDENTITY when omitted

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

if [[ -z "$PROVISIONING_PROFILE" ]]; then
  echo "error: REVOXA_PROVISIONING_PROFILE is not set." >&2
  echo "" >&2
  echo "Create/download a Mac App Store provisioning profile for $BUNDLE_ID," >&2
  echo "then re-run with:" >&2
  echo "  export REVOXA_PROVISIONING_PROFILE='/path/to/profile.provisionprofile'" >&2
  echo "" >&2
  echo "Common location:" >&2
  echo "  ~/Library/MobileDevice/Provisioning Profiles/" >&2
  exit 2
fi

if [[ ! -f "$PROVISIONING_PROFILE" ]]; then
  echo "error: provisioning profile not found: $PROVISIONING_PROFILE" >&2
  exit 2
fi

if [[ -z "$TEAM_ID" ]]; then
  TEAM_ID="$(printf '%s\n' "$SIGN_IDENTITY" | sed -n 's/.*(\([A-Z0-9][A-Z0-9]*\)).*/\1/p' | tail -1)"
fi

if [[ -z "$TEAM_ID" ]]; then
  echo "error: could not infer Team ID from REVOXA_SIGN_IDENTITY." >&2
  echo "Set it explicitly, for example:" >&2
  echo "  export REVOXA_TEAM_ID='5JAMN2986A'" >&2
  exit 2
fi

resolve_installer_identity() {
  if [[ -n "${REVOXA_INSTALLER_IDENTITY:-}" ]]; then
    echo "$REVOXA_INSTALLER_IDENTITY"
    return 0
  fi

  security find-identity -v -p basic \
    | grep -iE 'Mac Installer Distribution|3rd Party Mac Developer Installer' \
    | grep -v 'CSSMERR_TP_CERT_REVOKED' \
    | head -1 \
    | cut -d'"' -f2
}

write_installer_certificate_pem() {
  local identity="$1"
  local output="$2"

  if [[ "$identity" =~ ^[[:xdigit:]]{40}$ ]]; then
    local target_hash
    target_hash="$(printf '%s' "$identity" | tr '[:lower:]' '[:upper:]')"
    security find-certificate -a -Z -p | awk -v target_hash="$target_hash" -v output="$output" '
      /^SHA-1 hash: / {
        capture = ($3 == target_hash)
        next
      }
      capture {
        print > output
        if ($0 == "-----END CERTIFICATE-----") {
          found = 1
          capture = 0
        }
      }
      END {
        exit(found ? 0 : 1)
      }
    '
    return
  fi

  security find-certificate -c "$identity" -p >"$output"
}

echo "Building release Mac App Store app bundle..." >&2
"$ROOT_DIR/script/package_app.sh" --release --app-store >/dev/null

echo "Cleaning bundle metadata before signing..." >&2
clean_bundle_metadata "$APP_BUNDLE" >/dev/null

"$ROOT_DIR/script/verify_mac_app_store_entitlements.sh" "$APP_BUNDLE"

echo "Embedding provisioning profile..." >&2
cp "$PROVISIONING_PROFILE" "$EMBEDDED_PROFILE"
clean_bundle_metadata "$APP_BUNDLE" >/dev/null

cat >"$SIGNING_ENTITLEMENTS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.application-identifier</key>
  <string>$TEAM_ID.$BUNDLE_ID</string>
  <key>com.apple.developer.team-identifier</key>
  <string>$TEAM_ID</string>
  <key>keychain-access-groups</key>
  <array>
    <string>$TEAM_ID.*</string>
  </array>
  <key>com.apple.security.app-sandbox</key>
  <true/>
  <key>com.apple.security.network.client</key>
  <true/>
  <key>com.apple.security.files.user-selected.read-write</key>
  <true/>
</dict>
</plist>
PLIST

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

sign_app_path() {
  local target="$1"
  codesign --force --options runtime --timestamp \
    --sign "$SIGN_IDENTITY" \
    --identifier "$BUNDLE_ID" \
    --entitlements "$SIGNING_ENTITLEMENTS" \
    "$target"
}

echo "Signing resource bundle (if present)..." >&2
if [[ -d "$RESOURCE_BUNDLE" ]]; then
  sign_path "$RESOURCE_BUNDLE" "$RESOURCE_BUNDLE_ID"
fi

echo "Signing app binary with entitlements..." >&2
sign_app_path "$APP_BUNDLE/Contents/MacOS/Revoxa"

echo "Signing app bundle with entitlements..." >&2
sign_app_path "$APP_BUNDLE"

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE" >&2

embedded_entitlements="$(codesign -d --entitlements :- "$APP_BUNDLE" 2>/dev/null || true)"
binary_entitlements="$(codesign -d --entitlements :- "$APP_BUNDLE/Contents/MacOS/Revoxa" 2>/dev/null || true)"
echo "$embedded_entitlements" | grep -q "<key>com.apple.application-identifier</key>" \
  || {
    echo "error: signed app is missing com.apple.application-identifier entitlement" >&2
    exit 4
  }
echo "$embedded_entitlements" | grep -q "<string>$TEAM_ID.$BUNDLE_ID</string>" \
  || {
    echo "error: signed app application identifier does not match $TEAM_ID.$BUNDLE_ID" >&2
    exit 4
  }
echo "$binary_entitlements" | grep -q "<key>com.apple.application-identifier</key>" \
  || {
    echo "error: signed app binary is missing com.apple.application-identifier entitlement" >&2
    exit 4
  }
echo "$binary_entitlements" | grep -q "<string>$TEAM_ID.$BUNDLE_ID</string>" \
  || {
    echo "error: signed app binary application identifier does not match $TEAM_ID.$BUNDLE_ID" >&2
    exit 4
  }

if command -v xattr >/dev/null 2>&1; then
  echo "Removing quarantine attributes..." >&2
  xattr -dr com.apple.quarantine "$APP_BUNDLE" >/dev/null 2>&1 || true
fi

echo "Checking signed app bundle..." >&2
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
if ! write_installer_certificate_pem "$INSTALLER_IDENTITY" "$INSTALLER_CERT_PEM"; then
  echo "error: installer signing certificate not found in Keychain: $INSTALLER_IDENTITY" >&2
  exit 3
fi

if ! security verify-cert -c "$INSTALLER_CERT_PEM" -p basic -R ocsp -R require >/dev/null 2>&1; then
  echo "error: installer signing certificate failed revocation validation." >&2
  echo "Create a new Mac Installer Distribution / 3rd Party Mac Developer Installer certificate in Xcode," >&2
  echo "then re-run this script with REVOXA_INSTALLER_IDENTITY set to the new certificate name." >&2
  exit 3
fi

rm -f "$PKG_PATH"

echo "Preparing clean package staging bundle..." >&2
ditto --norsrc --noqtn "$APP_BUNDLE" "$STAGED_APP"
codesign --verify --deep --strict --verbose=2 "$STAGED_APP" >&2

echo "Creating installer package..." >&2
COPYFILE_DISABLE=1 productbuild \
  --component "$STAGED_APP" /Applications \
  --sign "$INSTALLER_IDENTITY" \
  "$PKG_PATH"

echo "Verifying packaged app payload..." >&2
rm -rf "$EXPANDED_PKG_DIR"
pkgutil --expand-full "$PKG_PATH" "$EXPANDED_PKG_DIR" >/dev/null
EXPANDED_APP="$(find "$EXPANDED_PKG_DIR" -path '*/Payload/Revoxa.app' -type d -print -quit)"
if [[ -z "$EXPANDED_APP" ]]; then
  echo "error: package payload is missing Revoxa.app" >&2
  rm -f "$PKG_PATH"
  exit 5
fi

if ! codesign --verify --deep --strict --verbose=2 "$EXPANDED_APP" >&2; then
  echo "error: packaged Revoxa.app failed codesign verification" >&2
  rm -f "$PKG_PATH"
  exit 5
fi

echo ""
echo "Ready for upload:"
echo "  $PKG_PATH"
echo ""
echo "Next steps:"
echo "  1. Open Transporter (Mac App Store)"
echo "  2. Add dist/Revoxa-macOS.pkg"
echo "  3. Deliver"
echo "  4. App Store Connect → Revoxa → TestFlight → macOS"
