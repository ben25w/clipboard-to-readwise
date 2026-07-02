#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1

APP_NAME="Clipboard to Readwise"
PROCESS_NAME="ClipboardToReadwise"
BUNDLE_ID="com.ben.clipboard-to-readwise"
MIN_SYSTEM_VERSION="13.0"
VERSION="${VERSION:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
SIGN_MODE="${SIGN_MODE:-adhoc}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
NOTARY_KEYCHAIN_PROFILE="${NOTARY_KEYCHAIN_PROFILE:-}"
CREATE_DMG="${CREATE_DMG:-0}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/release"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
ZIP_PATH="$RELEASE_DIR/Clipboard-to-Readwise-macOS.zip"
DMG_PATH="$RELEASE_DIR/Clipboard-to-Readwise-macOS.dmg"

if [[ "$SIGN_MODE" == "developer-id" && "$SIGN_IDENTITY" == "-" ]]; then
  SIGN_IDENTITY="$(security find-identity -v -p codesigning | awk -F'\"' '/Developer ID Application/ {print $2; exit}')"
  if [[ -z "$SIGN_IDENTITY" ]]; then
    echo "No Developer ID Application identity found. Set SIGN_IDENTITY or use SIGN_MODE=adhoc." >&2
    exit 1
  fi
fi

cd "$ROOT_DIR"
rm -rf "$RELEASE_DIR"
mkdir -p "$MACOS"

swift build -c release
BUILD_BINARY="$(swift build -c release --show-bin-path)/$PROCESS_NAME"
cp "$BUILD_BINARY" "$MACOS/$PROCESS_NAME"
chmod +x "$MACOS/$PROCESS_NAME"

cat >"$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$PROCESS_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.productivity</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

if [[ "$SIGN_MODE" == "developer-id" ]]; then
  codesign --force --timestamp --options runtime --sign "$SIGN_IDENTITY" "$APP_BUNDLE"
else
  codesign --force --deep --options runtime --sign - "$APP_BUNDLE"
fi

codesign --verify --strict --verbose=2 "$APP_BUNDLE"
spctl --assess --type execute --verbose=2 "$APP_BUNDLE" || true

ditto -c -k --norsrc --noextattr --keepParent "$APP_BUNDLE" "$ZIP_PATH"

if [[ "$SIGN_MODE" == "developer-id" && -n "$NOTARY_KEYCHAIN_PROFILE" ]]; then
  xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" --wait
  xcrun stapler staple "$APP_BUNDLE"
  rm -f "$ZIP_PATH"
  ditto -c -k --norsrc --noextattr --keepParent "$APP_BUNDLE" "$ZIP_PATH"
fi

if [[ "$CREATE_DMG" == "1" ]]; then
  rm -f "$DMG_PATH"
  hdiutil create -volname "$APP_NAME" -srcfolder "$APP_BUNDLE" -ov -format UDZO "$DMG_PATH"
fi

echo "Created $ZIP_PATH"
if [[ "$CREATE_DMG" == "1" ]]; then
  echo "Created $DMG_PATH"
fi
