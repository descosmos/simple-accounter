#!/bin/bash
# Rebuild native launcher assets from the imagegen master using macOS sips.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$PROJECT_DIR/assets/app_icon/app_icon.png"
ANDROID_RES="$PROJECT_DIR/android/app/src/main/res"
IOS_ICONS="$PROJECT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset"

resize_icon() {
  sips --resampleHeightWidth "$1" "$1" "$SOURCE" --out "$2" >/dev/null
}

for entry in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  density="${entry%:*}"
  pixels="${entry#*:}"
  resize_icon "$pixels" "$ANDROID_RES/mipmap-$density/ic_launcher.png"
done

# The adaptive XML controls sizing; nodpi prevents automatic density scaling.
mkdir -p "$ANDROID_RES/drawable-nodpi"
resize_icon 432 "$ANDROID_RES/drawable-nodpi/ic_launcher_artwork.png"

for icon in "$IOS_ICONS"/Icon-App-*.png; do
  filename="${icon##*/}"
  dimensions="${filename#Icon-App-}"
  points="${dimensions%%x*}"
  scale="${dimensions##*@}"
  scale="${scale%x.png}"
  pixels="$(awk -v points="$points" -v scale="$scale" 'BEGIN { printf "%.0f", points * scale }')"
  resize_icon "$pixels" "$icon"
done

echo "Updated Android and iOS launcher icons."
