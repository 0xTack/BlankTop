#!/bin/bash
# 分别打 Apple Silicon (arm64) 和 Intel (x86_64) 两个版本，只生成 dist，不安装。
set -euo pipefail
cd "$(dirname "$0")"

VERSION="1.1.0"
DIST="dist"
mkdir -p "$DIST"

SIGN_IDENTITY="${SIGN_IDENTITY:-BlankTop Local}"
SIGN_KEYCHAIN="${SIGN_KEYCHAIN:-$HOME/Library/Keychains/BlankTop-Signing.keychain-db}"
SIGN_KEYCHAIN_PASS="${SIGN_KEYCHAIN_PASS:-blanktop-signing}"

copy_resources() {
  local app="$1"
  if [ -f assets/Icon.icns ]; then cp assets/Icon.icns "$app/Contents/Resources/Icon.icns"; fi
  if [ -f assets/icon_1024.png ]; then cp assets/icon_1024.png "$app/Contents/Resources/hand.png"; fi
  for f in hand-open.pdf hand-closed.pdf hand-open.svg hand-closed.svg \
           hand-open.png hand-closed.png donation-qr.png; do
    if [ -f "assets/$f" ]; then cp "assets/$f" "$app/Contents/Resources/$f"; fi
  done
  for snd in assets/*.wav; do
    [ -f "$snd" ] || continue
    cp "$snd" "$app/Contents/Resources/$(basename "$snd")"
  done
}

build_arch() {
  local arch="$1" label="$2"
  local dir="build/$label"
  local app="$dir/BlankTop.app"

  echo "==> [$label] 编译 $arch"
  rm -rf "$dir"
  mkdir -p "$dir"

  clang -c -fobjc-arc -fmodules -Wall -arch "$arch" \
    -DHIDDENBAR_NATIVE_VISIBILITY=1 \
    -o "$dir/shim.o" HBNativeVisibilityShim.m

  swiftc -O -swift-version 5 -target "${arch}-apple-macos13.0" \
    -import-objc-header BlankTop-Bridging.h \
    main.swift IconStyle.swift BoxCat.swift CustomMode.swift CrazyGame.swift \
    HandPress.swift HandSVG.swift PeekArt.swift "$dir/shim.o" \
    -framework AppKit -framework ApplicationServices -framework Carbon \
    -o "$dir/BlankTop"

  mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
  cp "$dir/BlankTop" "$app/Contents/MacOS/BlankTop"
  cp Info.plist "$app/Contents/Info.plist"
  copy_resources "$app"

  if [ "$SIGN_IDENTITY" != "-" ] && [ -f "$SIGN_KEYCHAIN" ] && \
     security find-identity -p codesigning "$SIGN_KEYCHAIN" 2>/dev/null | grep -qF "$SIGN_IDENTITY"; then
    security unlock-keychain -p "$SIGN_KEYCHAIN_PASS" "$SIGN_KEYCHAIN" >/dev/null 2>&1 || true
    codesign --force --sign "$SIGN_IDENTITY" --keychain "$SIGN_KEYCHAIN" "$app"
  else
    codesign --force --sign - "$app"
  fi
  codesign --verify --verbose=2 "$app" >/dev/null

  echo "==> [$label] 生成 zip / dmg"
  rm -f "$DIST/BlankTop-${VERSION}-${label}.zip" "$DIST/BlankTop-${VERSION}-${label}.dmg"
  ditto -c -k --sequesterRsrc --keepParent "$app" "$DIST/BlankTop-${VERSION}-${label}.zip"

  local stage="$dir/dmg"
  rm -rf "$stage"; mkdir -p "$stage"
  cp -R "$app" "$stage/"
  ln -s /Applications "$stage/Applications"
  hdiutil create -volname "BlankTop ${VERSION}" -srcfolder "$stage" -ov -quiet \
    -format UDZO "$DIST/BlankTop-${VERSION}-${label}.dmg"
}

build_arch arm64 "arm64"
build_arch x86_64 "intel"

echo "==> 完成"
ls -lh "$DIST" | tail -6
