#!/bin/bash
# 下载最新 GitHub Actions debug APK
# token 从 ~/.netrc 或环境变量 GITHUB_TOKEN 读取
REPO="jiaoge2026/xinghai-app"
OUTPUT_DIR="${1:-.}"

TOKEN_FILE="$HOME/.github_token"
[ -f "$TOKEN_FILE" ] && TOKEN=$(cat "$TOKEN_FILE") || TOKEN="${GITHUB_TOKEN:-}"
[ -z "$TOKEN" ] && echo "ERROR: no token" && exit 1

ARTIFACT_ID=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "https://api.github.com/repos/$REPO/actions/artifacts?per_page=1" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['artifacts'][0]['id'])")

echo "Artifact: $ARTIFACT_ID"
rm -rf /tmp/apk-zip /tmp/apk-extract
mkdir /tmp/apk-extract

curl -s -L -o /tmp/apk-zip \
  -H "Authorization: Bearer $TOKEN" \
  "https://api.github.com/repos/$REPO/actions/artifacts/$ARTIFACT_ID/zip"

python3 -c "
import zipfile,os,shutil
with zipfile.ZipFile('/tmp/apk-zip') as z:
    z.extractall('/tmp/apk-extract')
for r,ds,fs in os.walk('/tmp/apk-extract'):
    for f in fs:
        if f.endswith('.apk'):
            dst=os.path.join('$OUTPUT_DIR','app-debug.apk')
            shutil.copy2(os.path.join(r,f),dst)
            print(f'OK: {dst} ({os.path.getsize(dst)/1e6:.1f}MB)')
"
rm -rf /tmp/apk-zip /tmp/apk-extract
