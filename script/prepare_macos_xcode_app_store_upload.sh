#!/usr/bin/env bash
# Archive and export the native macOS Xcode target for Mac App Store / TestFlight.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/Revoxa.xcodeproj"
SCHEME="Revoxa macOS"
BUNDLE_ID="com.revoxa.app"
ARCHIVE_PATH="$ROOT_DIR/build/Revoxa-macOS.xcarchive"
EXPORT_PATH="$ROOT_DIR/dist/xcode-macos-app-store"
PKG_PATH="$ROOT_DIR/dist/Revoxa-macOS.pkg"
PROFILE_PLIST="$(mktemp "${TMPDIR:-/tmp}/revoxa-profile-XXXXXX.plist")"
EXPORT_OPTIONS="$(mktemp "${TMPDIR:-/tmp}/revoxa-export-options-XXXXXX.plist")"
EXPANDED_PKG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/revoxa-xcode-expanded-pkg-XXXXXX")"
PROVISIONING_PROFILE="${REVOXA_PROVISIONING_PROFILE:-}"
TEAM_ID="${REVOXA_TEAM_ID:-}"
SIGNING_CERTIFICATE="${REVOXA_SIGNING_CERTIFICATE:-Apple Distribution}"
INSTALLER_SIGNING_CERTIFICATE="${REVOXA_INSTALLER_SIGNING_CERTIFICATE:-}"

cleanup() {
  rm -f "$PROFILE_PLIST"
  rm -f "$EXPORT_OPTIONS"
  rm -rf "$EXPANDED_PKG_DIR"
}
trap cleanup EXIT

usage() {
  cat <<EOF
usage: REVOXA_PROVISIONING_PROFILE='/path/to/profile.provisionprofile' $0

Creates an Xcode-produced Mac App Store package:
  1. Installs the Mac App Store provisioning profile locally
  2. Archives the Revoxa macOS Xcode target
  3. Exports a Mac App Store / TestFlight .pkg
  4. Copies the package to dist/Revoxa-macOS.pkg

Optional overrides:
  REVOXA_TEAM_ID='5JAMN2986A'
  REVOXA_BUILD_NUMBER='123'
  REVOXA_SIGNING_CERTIFICATE='Apple Distribution'
  REVOXA_INSTALLER_SIGNING_CERTIFICATE='Mac Installer Distribution'
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -z "$PROVISIONING_PROFILE" ]]; then
  if [[ -f "$ROOT_DIR/Revoxa_macOS_App_Store_015.provisionprofile" ]]; then
    PROVISIONING_PROFILE="$ROOT_DIR/Revoxa_macOS_App_Store_015.provisionprofile"
  else
    echo "error: REVOXA_PROVISIONING_PROFILE is not set." >&2
    usage >&2
    exit 2
  fi
fi

if [[ ! -f "$PROVISIONING_PROFILE" ]]; then
  echo "error: provisioning profile not found: $PROVISIONING_PROFILE" >&2
  exit 2
fi

security cms -D -i "$PROVISIONING_PROFILE" >"$PROFILE_PLIST"
PROFILE_UUID="$(/usr/libexec/PlistBuddy -c 'Print :UUID' "$PROFILE_PLIST")"
PROFILE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :Name' "$PROFILE_PLIST")"
PROFILE_TEAM_ID="$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' "$PROFILE_PLIST")"
PROFILE_APP_ID="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:com.apple.application-identifier' "$PROFILE_PLIST")"

if [[ -z "$TEAM_ID" ]]; then
  TEAM_ID="$PROFILE_TEAM_ID"
fi

if [[ "$PROFILE_APP_ID" != "$TEAM_ID.$BUNDLE_ID" ]]; then
  echo "error: provisioning profile application identifier is $PROFILE_APP_ID, expected $TEAM_ID.$BUNDLE_ID" >&2
  exit 2
fi

if [[ -z "$INSTALLER_SIGNING_CERTIFICATE" ]]; then
  INSTALLER_SIGNING_CERTIFICATE="$(
    security find-identity -v -p basic \
      | grep -iE 'Mac Installer Distribution|3rd Party Mac Developer Installer' \
      | grep -v 'CSSMERR_TP_CERT_REVOKED' \
      | awk '{print $2; exit}'
  )"
fi

if [[ -z "$INSTALLER_SIGNING_CERTIFICATE" ]]; then
  echo "error: valid Mac Installer Distribution certificate not found." >&2
  echo "Create one in Xcode -> Settings -> Accounts -> Manage Certificates -> + -> Mac Installer Distribution." >&2
  exit 3
fi

PROFILE_INSTALL_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROFILE_INSTALL_DIR"
cp "$PROVISIONING_PROFILE" "$PROFILE_INSTALL_DIR/$PROFILE_UUID.provisionprofile"

echo "Syncing Xcode project version/build settings..." >&2
ruby "$ROOT_DIR/script/generate_ios_xcodeproj.rb"

cat >"$EXPORT_OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>destination</key>
  <string>export</string>
  <key>installerSigningCertificate</key>
  <string>$INSTALLER_SIGNING_CERTIFICATE</string>
  <key>manageAppVersionAndBuildNumber</key>
  <false/>
  <key>method</key>
  <string>app-store-connect</string>
  <key>provisioningProfiles</key>
  <dict>
    <key>$BUNDLE_ID</key>
    <string>$PROFILE_NAME</string>
  </dict>
  <key>signingCertificate</key>
  <string>$SIGNING_CERTIFICATE</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>teamID</key>
  <string>$TEAM_ID</string>
  <key>testFlightInternalTestingOnly</key>
  <true/>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
PLIST

echo "Using provisioning profile: $PROFILE_NAME ($PROFILE_UUID)" >&2
echo "Using team: $TEAM_ID" >&2
echo "Using app signing certificate: $SIGNING_CERTIFICATE" >&2
echo "Using installer signing certificate: $INSTALLER_SIGNING_CERTIFICATE" >&2
echo "Archiving $SCHEME..." >&2
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$SIGNING_CERTIFICATE" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  PROVISIONING_PROFILE_SPECIFIER="$PROFILE_NAME" \
  archive

echo "Exporting Mac App Store package..." >&2
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS"

EXPORTED_PKG="$(find "$EXPORT_PATH" -maxdepth 2 -name '*.pkg' -type f -print -quit)"
if [[ -z "$EXPORTED_PKG" ]]; then
  echo "error: export did not produce a .pkg in $EXPORT_PATH" >&2
  find "$EXPORT_PATH" -maxdepth 3 -print >&2 || true
  exit 5
fi

cp "$EXPORTED_PKG" "$PKG_PATH"

echo "Verifying exported package signature..." >&2
pkgutil --check-signature "$PKG_PATH" >&2

echo "Verifying exported package payload..." >&2
rm -rf "$EXPANDED_PKG_DIR"
pkgutil --expand-full "$PKG_PATH" "$EXPANDED_PKG_DIR" >/dev/null
EXPANDED_APP="$(find "$EXPANDED_PKG_DIR" -path '*/Payload/Revoxa.app' -type d -print -quit)"
if [[ -z "$EXPANDED_APP" ]]; then
  echo "error: exported package payload is missing Revoxa.app" >&2
  exit 5
fi

codesign --verify --deep --strict --verbose=2 "$EXPANDED_APP" >&2

echo ""
echo "Ready for Transporter:"
echo "  $PKG_PATH"
echo ""
echo "Upload this package as the next macOS TestFlight build."
