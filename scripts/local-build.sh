#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# 读取当前版本号，递增
VERSION=$(cat .version 2>/dev/null || echo "0")
# 解析 major.minor.build (忽略+号后缀)
BASE=${VERSION%+*}
BUILD_NUM=${VERSION##*+}
BUILD_NUM=$((BUILD_NUM + 1))
NEW_VERSION="${BASE}+${BUILD_NUM}"

echo "版本: $VERSION → $NEW_VERSION"
echo "$NEW_VERSION" > .version

# 更新 pubspec.yaml
sed -i "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml

# 触发 Flutter 构建
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://pub.flutter-io.cn

/home/admin/flutter/bin/flutter build apk --debug

# 复制到分发目录
cp build/app/outputs/flutter-apk/app-debug.apk /home/admin/xinghai-web/dist/app-debug.apk
echo "APK已生成: /home/admin/xinghai-web/dist/app-debug.apk"
