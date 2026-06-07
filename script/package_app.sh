#!/usr/bin/env bash
# Assembles dist/Revoxa.app from a SwiftPM build.
set -euo pipefail

APP_NAME="Revoxa"
BUNDLE_ID="com.revoxa.app"
MIN_SYSTEM_VERSION="14.0"
LS_CATEGORY="public.app-category.productivity"

CONFIGURATION="debug"
SKIP_ENTITLEMENTS=false
VERIFY_MAC_APP_STORE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --configuration)
      CONFIGURATION="${2:?--configuration requires release or debug}"
      shift 2
      ;;
    --release)
      CONFIGURATION="release"
      shift
      ;;
    --debug)
      CONFIGURATION="debug"
      shift
      ;;
    --app-store)
      VERIFY_MAC_APP_STORE=true
      shift
      ;;
    --skip-entitlements)
      SKIP_ENTITLEMENTS=true
      shift
      ;;
    -h|--help)
      echo "usage: $0 [--configuration release|debug] [--release|--debug] [--app-store] [--skip-entitlements]" >&2
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ "$CONFIGURATION" != "release" && "$CONFIGURATION" != "debug" ]]; then
  echo "error: configuration must be release or debug (got: $CONFIGURATION)" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENTITLEMENTS_FILE="$ROOT_DIR/Configurations/Revoxa-macOS/Revoxa-macOS.entitlements"
VERSION_FILE="$ROOT_DIR/VERSION"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
PKG_INFO="$APP_CONTENTS/PkgInfo"
APP_ICON_ICNS="$ROOT_DIR/AppIcon/AppIcon.icns"
ASSETS_CATALOG="$ROOT_DIR/Sources/Revoxa/Resources/Assets.xcassets"
LOCALIZABLE_XCSTRINGS="$ROOT_DIR/Sources/Revoxa/Resources/Localizable.xcstrings"

if [[ -f "$VERSION_FILE" ]]; then
  APP_VERSION="$(tr -d '[:space:]' <"$VERSION_FILE")"
else
  APP_VERSION="0.1.0"
fi

"$ROOT_DIR/script/generate_app_icon.sh" >&2

echo "Building Revoxa ($CONFIGURATION)..." >&2
swift build -c "$CONFIGURATION"
BUILD_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
BUILD_BINARY="$BUILD_DIR/$APP_NAME"
RESOURCE_BUNDLE="$BUILD_DIR/${APP_NAME}_${APP_NAME}.bundle"

if [[ ! -f "$BUILD_BINARY" ]]; then
  echo "error: missing build product $BUILD_BINARY" >&2
  exit 1
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

if [[ -d "$RESOURCE_BUNDLE" ]]; then
  PACKAGED_RESOURCE_BUNDLE="$APP_MACOS/$(basename "$RESOURCE_BUNDLE")"
  rm -rf "$PACKAGED_RESOURCE_BUNDLE"
  cp -R "$RESOURCE_BUNDLE" "$APP_MACOS/"

  # SPM ships raw .xcstrings; the packaged .app needs compiled .lproj catalogs at runtime.
  if [[ -f "$LOCALIZABLE_XCSTRINGS" ]] && command -v xcrun >/dev/null 2>&1; then
    xcrun xcstringstool compile "$LOCALIZABLE_XCSTRINGS" --output-directory "$PACKAGED_RESOURCE_BUNDLE" >&2
  fi
fi

if [[ ! -f "$APP_ICON_ICNS" ]]; then
  echo "error: missing $APP_ICON_ICNS (run script/generate_app_icon.sh)" >&2
  exit 1
fi

ACTOOL_PARTIAL_PLIST="$(mktemp "${TMPDIR:-/tmp}/revoxa-actool-XXXXXX.plist")"
cleanup_actool_partial() {
  rm -f "$ACTOOL_PARTIAL_PLIST"
}
trap cleanup_actool_partial EXIT

if command -v xcrun >/dev/null 2>&1; then
  echo "Compiling asset catalog (AppIcon only)..." >&2
  xcrun actool \
    --compile "$APP_RESOURCES" \
    --platform macosx \
    --minimum-deployment-target "$MIN_SYSTEM_VERSION" \
    --app-icon AppIcon \
    --output-partial-info-plist "$ACTOOL_PARTIAL_PLIST" \
    "$ASSETS_CATALOG" >&2
else
  echo "warning: xcrun not found; copying prebuilt AppIcon.icns only" >&2
  cp "$APP_ICON_ICNS" "$APP_RESOURCES/AppIcon.icns"
fi

if [[ ! -f "$APP_RESOURCES/AppIcon.icns" ]]; then
  echo "warning: actool did not emit AppIcon.icns; using $APP_ICON_ICNS" >&2
  cp "$APP_ICON_ICNS" "$APP_RESOURCES/AppIcon.icns"
fi

# Keep the full iconset-backed .icns in the bundle. actool can emit a compact
# .icns that is sufficient for some surfaces, while Stage Manager may request
# larger representations directly from CFBundleIconFile.
cp "$APP_ICON_ICNS" "$APP_RESOURCES/AppIcon.icns"

if [[ ! -f "$APP_RESOURCES/Assets.car" ]]; then
  echo "error: missing Assets.car after actool (app icon will not appear in all system surfaces)" >&2
  exit 1
fi

printf 'APPL????' >"$PKG_INFO"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>tr</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_VERSION</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIconName</key>
  <string>AppIcon</string>
  <key>CFBundleIcons</key>
  <dict>
    <key>CFBundlePrimaryIcon</key>
    <dict>
      <key>CFBundleIconFiles</key>
      <array>
        <string>AppIcon</string>
      </array>
      <key>CFBundleIconName</key>
      <string>AppIcon</string>
    </dict>
  </dict>
  <key>CFBundleIcons~mac</key>
  <dict>
    <key>CFBundlePrimaryIcon</key>
    <dict>
      <key>CFBundleIconFiles</key>
      <array>
        <string>AppIcon</string>
      </array>
      <key>CFBundleIconName</key>
      <string>AppIcon</string>
    </dict>
  </dict>
  <key>NSUserNotificationUsageDescription</key>
  <string>Revoxa sends local reminders before your subscription renewals.</string>
  <key>NSUserNotificationsUsageDescription</key>
  <string>Revoxa sends local reminders before your subscription renewals.</string>
  <key>LSApplicationCategoryType</key>
  <string>$LS_CATEGORY</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright © $(date +%Y) Revoxa. Personal use.</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

"$ROOT_DIR/script/verify_app_bundle.sh" "$APP_BUNDLE" >&2 || {
  echo "warning: bundle verification reported issues (see above)" >&2
}

if command -v codesign >/dev/null 2>&1; then
  sign_target() {
    local -a sign_args=(--force --sign - --identifier "$BUNDLE_ID" --timestamp=none)
    if [[ "$SKIP_ENTITLEMENTS" != true && -f "$ENTITLEMENTS_FILE" ]]; then
      sign_args+=(--entitlements "$ENTITLEMENTS_FILE")
    fi
    codesign "${sign_args[@]}" "$1"
  }
  if [[ -d "$PACKAGED_RESOURCE_BUNDLE" ]]; then
    sign_target "$PACKAGED_RESOURCE_BUNDLE" >/dev/null 2>&1 || true
  fi
  sign_target "$APP_BINARY"
  sign_target "$APP_BUNDLE"
fi

if [[ "$VERIFY_MAC_APP_STORE" == true ]]; then
  "$ROOT_DIR/script/verify_mac_app_store_entitlements.sh" "$APP_BUNDLE" >&2
fi

echo "$APP_BUNDLE"
