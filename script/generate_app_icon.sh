#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ICON="$ROOT_DIR/AppIcon/RevoxaAppIconSource.png"
ICONSET_DIR="$ROOT_DIR/AppIcon/AppIcon.iconset"
APPICONSET_DIR="$ROOT_DIR/Sources/Revoxa/Resources/Assets.xcassets/AppIcon.appiconset"
ICNS_OUTPUT="$ROOT_DIR/AppIcon/AppIcon.icns"

if [[ ! -f "$SOURCE_ICON" ]]; then
  echo "error: source icon not found at $SOURCE_ICON" >&2
  exit 1
fi

mkdir -p "$ICONSET_DIR" "$APPICONSET_DIR"
rm -f "$ICONSET_DIR"/*.png "$APPICONSET_DIR"/*.png

write_icon() {
  local pixel_size="$1"
  local filename="$2"

  sips -s format png -z "$pixel_size" "$pixel_size" "$SOURCE_ICON" --out "$ICONSET_DIR/$filename" >/dev/null
  cp "$ICONSET_DIR/$filename" "$APPICONSET_DIR/$filename"
}

write_appicon() {
  local pixel_size="$1"
  local filename="$2"

  sips -s format png -z "$pixel_size" "$pixel_size" "$SOURCE_ICON" --out "$APPICONSET_DIR/$filename" >/dev/null
}

# macOS iconset + appiconset pixel sizes
write_icon 16 "icon_16x16.png"
write_icon 32 "icon_16x16@2x.png"
write_icon 32 "icon_32x32.png"
write_icon 64 "icon_32x32@2x.png"
write_icon 128 "icon_128x128.png"
write_icon 256 "icon_128x128@2x.png"
write_icon 256 "icon_256x256.png"
write_icon 512 "icon_256x256@2x.png"
write_icon 512 "icon_512x512.png"
write_icon 1024 "icon_512x512@2x.png"

# iOS appiconset pixel sizes
write_appicon 40 "icon_ios_20x20@2x.png"
write_appicon 60 "icon_ios_20x20@3x.png"
write_appicon 58 "icon_ios_29x29@2x.png"
write_appicon 87 "icon_ios_29x29@3x.png"
write_appicon 80 "icon_ios_40x40@2x.png"
write_appicon 120 "icon_ios_40x40@3x.png"
write_appicon 120 "icon_ios_60x60@2x.png"
write_appicon 180 "icon_ios_60x60@3x.png"

write_appicon 20 "icon_ipad_20x20.png"
write_appicon 40 "icon_ipad_20x20@2x.png"
write_appicon 29 "icon_ipad_29x29.png"
write_appicon 58 "icon_ipad_29x29@2x.png"
write_appicon 40 "icon_ipad_40x40.png"
write_appicon 80 "icon_ipad_40x40@2x.png"
write_appicon 152 "icon_ipad_76x76@2x.png"
write_appicon 167 "icon_ipad_83.5x83.5@2x.png"

if iconutil -c icns "$ICONSET_DIR" -o "$ICNS_OUTPUT"; then
  :
elif [[ -f "$ICNS_OUTPUT" ]]; then
  echo "warning: iconutil rejected $ICONSET_DIR; keeping existing $ICNS_OUTPUT" >&2
else
  echo "error: iconutil rejected $ICONSET_DIR and no existing $ICNS_OUTPUT is available" >&2
  exit 1
fi

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
  icon_ios_20x20@2x.png
  icon_ios_20x20@3x.png
  icon_ios_29x29@2x.png
  icon_ios_29x29@3x.png
  icon_ios_40x40@2x.png
  icon_ios_40x40@3x.png
  icon_ios_60x60@2x.png
  icon_ios_60x60@3x.png
  icon_ipad_20x20.png
  icon_ipad_20x20@2x.png
  icon_ipad_29x29.png
  icon_ipad_29x29@2x.png
  icon_ipad_40x40.png
  icon_ipad_40x40@2x.png
  icon_ipad_76x76@2x.png
  icon_ipad_83.5x83.5@2x.png
)
for png in "${required_pngs[@]}"; do
  if [[ ! -f "$APPICONSET_DIR/$png" ]]; then
    echo "error: expected $APPICONSET_DIR/$png after generation" >&2
    exit 1
  fi
done

echo "Generated AppIcon.icns and AppIcon.appiconset assets from $SOURCE_ICON" >&2
