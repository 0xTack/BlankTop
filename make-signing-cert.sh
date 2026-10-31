#!/bin/bash
# 创建一张固定的本地代码签名证书，替代 ad-hoc 签名。
#
# 为什么要这么做：
#   ad-hoc 签名（codesign --sign -）没有证书，系统只能用二进制哈希（cdhash）
#   记住这个 App。每次重新编译 cdhash 都会变，辅助功能授权就失效了——面板里
#   看着还勾着，App 却一直说没权限。换成固定证书后，签名要求变成
#   "identifier + certificate leaf"，重编译不会再把授权弄掉。
#
# 证书放在一个专用钥匙串里（不在登录钥匙串），这样构建时不需要任何
# 弹窗或密码输入。删掉这个文件即可彻底移除：
#   ~/Library/Keychains/BlankTop-Signing.keychain-db
set -euo pipefail

NAME="BlankTop Local"
KEYCHAIN="$HOME/Library/Keychains/BlankTop-Signing.keychain-db"
PASS="blanktop-signing"
DIR="$HOME/Library/Application Support/BlankTop/signing"

if security find-identity -p codesigning "$KEYCHAIN" 2>/dev/null | grep -qF "$NAME"; then
  echo "==> 已存在签名身份：$NAME"
  exit 0
fi

echo "==> 生成自签名证书（10 年有效）"
mkdir -p "$DIR"
chmod 700 "$DIR"
openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 3650 \
  -keyout "$DIR/key.pem" -out "$DIR/cert.pem" \
  -subj "/CN=$NAME" \
  -addext "basicConstraints=critical,CA:false" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning" 2>/dev/null

openssl pkcs12 -export -inkey "$DIR/key.pem" -in "$DIR/cert.pem" \
  -out "$DIR/identity.p12" -passout "pass:$PASS" -name "$NAME" 2>/dev/null

echo "==> 创建专用钥匙串"
security create-keychain -p "$PASS" "$KEYCHAIN"
security unlock-keychain -p "$PASS" "$KEYCHAIN"
security import "$DIR/identity.p12" -k "$KEYCHAIN" -P "$PASS" \
  -T /usr/bin/codesign -T /usr/bin/security -A
# 让 codesign 不需要交互就能拿到私钥，否则会报 errSecInternalComponent。
security set-key-partition-list -S apple-tool:,apple:,codesign: \
  -s -k "$PASS" "$KEYCHAIN" >/dev/null

rm -f "$DIR/identity.p12" "$DIR/key.pem"
chmod 600 "$DIR/cert.pem"

if security find-identity -p codesigning "$KEYCHAIN" 2>/dev/null | grep -qF "$NAME"; then
  echo "==> 完成：$NAME"
  echo "    现在运行 ./build.sh 或 ./package.sh，签名会用它。"
else
  echo "!! 创建失败，请把上面的输出发给我。"
  exit 1
fi
