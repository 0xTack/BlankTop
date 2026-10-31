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
  main.swift build/shim.o \
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

echo "==> ad-hoc 签名"
codesign --force --sign - "$APP"
codesign --verify --verbose=2 "$APP"

echo "==> 完成：$APP"
