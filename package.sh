#!/bin/bash
# 打包 BlankTop 1.0：生成可分发用的 zip 和 dmg，并安装到 /Applications。
set -euo pipefail
cd "$(dirname "$0")"

VERSION="1.0.1"
./build.sh

echo "==> 清理旧版本"
pkill -f "BlankTop.app/Contents/MacOS/BlankTop" 2>/dev/null || true
pkill -f "MenuBarFold.app/Contents/MacOS/MenuBarFold" 2>/dev/null || true
rm -rf /Applications/MenuBarFold.app
rm -f ~/Library/LaunchAgents/com.xa.menubarfold.plist

echo "==> 安装到 /Applications"
rm -rf "/Applications/BlankTop.app"
cp -R BlankTop.app /Applications/

echo "==> 生成 zip"
rm -rf dist
mkdir -p dist
ditto -c -k --sequesterRsrc --keepParent BlankTop.app "dist/BlankTop-${VERSION}.zip"

echo "==> 生成 dmg"
STAGE="build/dmg"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R BlankTop.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "dist/BlankTop-${VERSION}.dmg"
hdiutil create -volname "BlankTop ${VERSION}" -srcfolder "$STAGE" -ov -quiet \
  -format UDZO "dist/BlankTop-${VERSION}.dmg"

echo "==> 完成"
ls -lh dist
