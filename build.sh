#!/bin/bash
# 编译 BlankTop：只需要 Command Line Tools，不需要完整 Xcode。
set -euo pipefail
cd "$(dirname "$0")"

APP="BlankTop.app"
BIN="BlankTop"

rm -rf build "$APP"
mkdir -p build

echo "==> 编译 ObjC 桥接层"
clang -c -fobjc-arc -fmodules -Wall \
  -DHIDDENBAR_NATIVE_VISIBILITY=1 \
  -o build/shim.o HBNativeVisibilityShim.m

echo "==> 编译 Swift 主体"
swiftc -O -swift-version 5 \
  -import-objc-header BlankTop-Bridging.h \
  main.swift IconStyle.swift BoxCat.swift CustomMode.swift CrazyGame.swift HandPress.swift HandSVG.swift PeekArt.swift build/shim.o \
  -framework AppKit -framework ApplicationServices -framework Carbon \
  -o "build/$BIN"

echo "==> 组装 app bundle"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "build/$BIN" "$APP/Contents/MacOS/$BIN"
cp Info.plist "$APP/Contents/Info.plist"
if [ -f assets/Icon.icns ]; then
  cp assets/Icon.icns "$APP/Contents/Resources/Icon.icns"
else
  echo "    警告：assets/Icon.icns 不存在，将使用默认图标"
fi
if [ -f assets/icon_1024.png ]; then
  cp assets/icon_1024.png "$APP/Contents/Resources/hand.png"
fi
if [ -f assets/hand-open.pdf ]; then
  cp assets/hand-open.pdf "$APP/Contents/Resources/hand-open.pdf"
fi
if [ -f assets/hand-closed.pdf ]; then
  cp assets/hand-closed.pdf "$APP/Contents/Resources/hand-closed.pdf"
fi
if [ -f assets/hand-open.png ]; then
  cp assets/hand-open.png "$APP/Contents/Resources/hand-open.png"
fi
if [ -f assets/hand-closed.png ]; then
  cp assets/hand-closed.png "$APP/Contents/Resources/hand-closed.png"
fi
if [ -f assets/hand-open.svg ]; then
  cp assets/hand-open.svg "$APP/Contents/Resources/hand-open.svg"
fi
if [ -f assets/hand-closed.svg ]; then
  cp assets/hand-closed.svg "$APP/Contents/Resources/hand-closed.svg"
fi
for snd in assets/*.wav; do
  [ -f "$snd" ] || continue
  cp "$snd" "$APP/Contents/Resources/$(basename "$snd")"
done
if [ -f assets/donation-qr.png ]; then
  cp assets/donation-qr.png "$APP/Contents/Resources/donation-qr.png"
fi

echo "==> 签名"
# 用固定的本地证书签名。ad-hoc 签名（--sign -）会让签名要求变成 cdhash，
# 每次编译都会换一个身份，系统的辅助功能授权随即失效。
# 没有证书时退回 ad-hoc，并提示先运行 make-signing-cert.sh。
SIGN_IDENTITY="${SIGN_IDENTITY:-BlankTop Local}"
SIGN_KEYCHAIN="${SIGN_KEYCHAIN:-$HOME/Library/Keychains/BlankTop-Signing.keychain-db}"
SIGN_KEYCHAIN_PASS="${SIGN_KEYCHAIN_PASS:-blanktop-signing}"
if [ "$SIGN_IDENTITY" != "-" ] && [ -f "$SIGN_KEYCHAIN" ] && \
   security find-identity -p codesigning "$SIGN_KEYCHAIN" 2>/dev/null | grep -qF "$SIGN_IDENTITY"; then
  security unlock-keychain -p "$SIGN_KEYCHAIN_PASS" "$SIGN_KEYCHAIN" >/dev/null 2>&1 || true
  echo "    使用：$SIGN_IDENTITY"
  codesign --force --sign "$SIGN_IDENTITY" --keychain "$SIGN_KEYCHAIN" "$APP"
else
  if [ "$SIGN_IDENTITY" != "-" ]; then
    echo "    警告：没找到签名身份「$SIGN_IDENTITY」，退回 ad-hoc。"
    echo "    这样每次重新编译，辅助功能授权都会失效。先运行 ./make-signing-cert.sh"
  fi
  codesign --force --sign - "$APP"
fi
codesign --verify --verbose=2 "$APP"

echo "==> 完成：$APP"
