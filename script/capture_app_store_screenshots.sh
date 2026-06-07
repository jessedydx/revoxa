#!/usr/bin/env bash
# Captures raw App Store screenshots in screenshot-fixture mode (dark, English, USD),
# then composes marketing frames via generate_app_store_screenshots.swift.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCREENS_DIR="$ROOT_DIR/docs/app-store-assets/screenshots/raw"
DERIVED_DATA="$ROOT_DIR/build/screenshot-derived"
BUNDLE_ID="com.revoxa.app"
IPHONE_UDID="${REVOXA_SCREENSHOT_IPHONE_UDID:-CB45B391-ACF2-4F0B-B9F9-7896DDC6178D}"
IPAD_UDID="${REVOXA_SCREENSHOT_IPAD_UDID:-9BB21054-FE4D-4EFA-B20D-0E7E66A7D523}"

mkdir -p "$SCREENS_DIR/iphone" "$SCREENS_DIR/ipad" "$SCREENS_DIR/macos"

boot_simulator() {
  local udid="$1"
  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  open -a Simulator --args -CurrentDeviceUDID "$udid" >/dev/null 2>&1 || true
  sleep 2
}

capture_ios() {
  local udid="$1"
  local section="$2"
  local output="$3"
  local scene="${4:-}"
  local wait_seconds=8

  if [[ -n "$scene" ]]; then
    wait_seconds=12
  fi

  local -a launch_args=(
    --revoxa-screenshot-fixtures
    "--revoxa-screenshot-section=$section"
  )
  if [[ -n "$scene" ]]; then
    launch_args+=("--revoxa-screenshot-scene=$scene")
  fi

  boot_simulator "$udid"

  xcrun simctl status_bar "$udid" override \
    --time "9:41" \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --cellularMode active \
    --cellularBars 4 \
    --batteryState charged \
    --batteryLevel 100 \
    >/dev/null 2>&1 || true

  xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl launch "$udid" "$BUNDLE_ID" "${launch_args[@]}" >/dev/null
  sleep "$wait_seconds"
  xcrun simctl io "$udid" screenshot "$output" 2>/dev/null | grep -v "Detected file type" | grep -v "Note: No display" | grep -v "Wrote screenshot" || true
  xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true

  echo "Captured $(basename "$output")"
}

capture_macos() {
  local section="$1"
  local output="$2"
  local scene="${3:-}"

  local -a launch_args=(
    --revoxa-screenshot-fixtures
    "--revoxa-screenshot-section=$section"
    "--revoxa-screenshot-output=$output"
  )
  if [[ -n "$scene" ]]; then
    launch_args+=("--revoxa-screenshot-scene=$scene")
  fi

  "$ROOT_DIR/dist/Revoxa.app/Contents/MacOS/Revoxa" "${launch_args[@]}" >/dev/null 2>&1 || true

  if [[ ! -f "$output" ]]; then
    echo "error: macOS screenshot missing: $output" >&2
    exit 1
  fi

  echo "Captured $(basename "$output")"
}

echo "Building iOS app for simulator..."
xcodebuild \
  -project "$ROOT_DIR/Revoxa.xcodeproj" \
  -scheme "Revoxa iOS" \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  build >/dev/null

IOS_APP="$(find "$DERIVED_DATA" -path "*iphonesimulator/Revoxa.app" -type d | head -1)"
if [[ -z "$IOS_APP" || ! -d "$IOS_APP" ]]; then
  echo "error: could not locate built iOS app bundle" >&2
  exit 1
fi

echo "Installing iOS app on simulators..."
boot_simulator "$IPHONE_UDID"
boot_simulator "$IPAD_UDID"
xcrun simctl install "$IPHONE_UDID" "$IOS_APP" >/dev/null
xcrun simctl install "$IPAD_UDID" "$IOS_APP" >/dev/null

echo "Capturing iPhone screenshots..."
capture_ios "$IPHONE_UDID" dashboard "$SCREENS_DIR/iphone/01-dashboard.png"
capture_ios "$IPHONE_UDID" subscriptions "$SCREENS_DIR/iphone/02-subscriptions.png"
capture_ios "$IPHONE_UDID" calendar "$SCREENS_DIR/iphone/03-calendar.png"
capture_ios "$IPHONE_UDID" calendar "$SCREENS_DIR/iphone/04-day-modal.png" day-modal
capture_ios "$IPHONE_UDID" dashboard "$SCREENS_DIR/iphone/05-edit-form.png" edit-form
capture_ios "$IPHONE_UDID" settings "$SCREENS_DIR/iphone/06-settings.png"

echo "Capturing iPad screenshots..."
capture_ios "$IPAD_UDID" dashboard "$SCREENS_DIR/ipad/01-dashboard.png"
capture_ios "$IPAD_UDID" calendar "$SCREENS_DIR/ipad/02-calendar.png"
capture_ios "$IPAD_UDID" subscriptions "$SCREENS_DIR/ipad/03-subscriptions.png"
capture_ios "$IPAD_UDID" settings "$SCREENS_DIR/ipad/04-settings.png"

echo "Building macOS app..."
"$ROOT_DIR/script/build_and_run.sh" --package-only >/dev/null

echo "Capturing macOS screenshots..."
capture_macos dashboard "$SCREENS_DIR/macos/01-dashboard.png"
capture_macos subscriptions "$SCREENS_DIR/macos/02-subscriptions.png"
capture_macos calendar "$SCREENS_DIR/macos/03-calendar.png"
capture_macos settings "$SCREENS_DIR/macos/04-settings.png"

echo "Composing App Store marketing screenshots..."
(
  cd "$ROOT_DIR"
  swift script/generate_app_store_screenshots.swift
)

echo "Done. Final assets: $ROOT_DIR/docs/app-store-assets/screenshots/final/"
