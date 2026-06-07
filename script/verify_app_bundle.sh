#!/usr/bin/env bash
# Post-build checks for Revoxa.app icon metadata and embedded resources.
set -euo pipefail

APP_NAME="Revoxa"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPICONSET_DIR="$ROOT_DIR/Sources/Revoxa/Resources/Assets.xcassets/AppIcon.appiconset"

APP_BUNDLE="${1:-$ROOT_DIR/dist/$APP_NAME.app}"

fail() {
  echo "verify: FAIL — $*" >&2
  exit 1
}

pass() {
  echo "verify: OK — $*"
}

if [[ ! -d "$APP_BUNDLE" ]]; then
  fail "app bundle not found: $APP_BUNDLE"
fi

INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"
ICNS_PATH="$RESOURCES_DIR/AppIcon.icns"
CAR_PATH="$RESOURCES_DIR/Assets.car"
required_pngs=(
  icon_16x16.png
  icon_16x16@2x.png
  icon_32x32.png
  icon_32x32@2x.png
  icon_128x128.png
  icon_128x128@2x.png
  icon_256x256.png
  icon_256x256@2x.png
  icon_512x512.png
  icon_512x512@2x.png
)

[[ -f "$INFO_PLIST" ]] || fail "missing Info.plist"
[[ -f "$ICNS_PATH" ]] || fail "missing AppIcon.icns in Resources"
[[ -s "$ICNS_PATH" ]] || fail "AppIcon.icns is empty"
[[ -f "$CAR_PATH" ]] || fail "missing Assets.car (run actool during package_app.sh)"

for key in CFBundleIconFile CFBundleIconName; do
  value="$(/usr/libexec/PlistBuddy -c "Print :$key" "$INFO_PLIST" 2>/dev/null || true)"
  [[ "$value" == "AppIcon" ]] || fail "Info.plist $key expected AppIcon, got: ${value:-<missing>}"
done

for key in CFBundleIcons CFBundleIcons~mac; do
  /usr/libexec/PlistBuddy -c "Print :$key:CFBundlePrimaryIcon:CFBundleIconName" "$INFO_PLIST" >/dev/null 2>&1 \
    || fail "Info.plist missing $key → CFBundlePrimaryIcon → CFBundleIconName"
done

bundle_id="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST" 2>/dev/null || true)"
[[ "$bundle_id" == "com.revoxa.app" ]] || fail "unexpected CFBundleIdentifier: ${bundle_id:-<missing>}"

display_name="$(/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$INFO_PLIST" 2>/dev/null || true)"
[[ "$display_name" == "$APP_NAME" ]] || fail "unexpected CFBundleDisplayName: ${display_name:-<missing>}"

if [[ -d "$APPICONSET_DIR" ]]; then
  for png in "${required_pngs[@]}"; do
    [[ -f "$APPICONSET_DIR/$png" ]] || fail "AppIcon.appiconset missing $png (run script/generate_app_icon.sh)"
  done
  pass "AppIcon.appiconset has all 10 macOS PNG sizes"
fi

if [[ -f "$APP_BUNDLE/Contents/MacOS/Revoxa_MenuBarIcon.png" ]] || \
   plutil -p "$INFO_PLIST" 2>/dev/null | grep -q MenuBarIcon; then
  fail "MenuBarIcon must not replace AppIcon in bundle metadata"
fi

file_type="$(file -b "$ICNS_PATH")"
[[ "$file_type" == *"Mac OS X icon"* ]] || fail "AppIcon.icns is not a valid icns: $file_type"

ICNS_CHECK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/revoxa-icns-check-XXXXXX.iconset")"
cleanup_icns_check() {
  rm -rf "$ICNS_CHECK_DIR"
}
trap cleanup_icns_check EXIT

iconutil -c iconset "$ICNS_PATH" -o "$ICNS_CHECK_DIR" >/dev/null 2>&1 \
  || fail "AppIcon.icns cannot be expanded with iconutil"

for png in "${required_pngs[@]}"; do
  [[ -f "$ICNS_CHECK_DIR/$png" ]] || fail "AppIcon.icns missing $png"
done

pass "bundle icon files present ($APP_BUNDLE)"
pass "Info.plist icon keys (CFBundleIcons + CFBundleIcons~mac)"
pass "AppIcon.icns has all 10 macOS icon representations"
echo "verify: all checks passed for $APP_BUNDLE"
