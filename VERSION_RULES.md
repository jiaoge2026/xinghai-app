# Flutter App 版本规则

## 版本号格式
```
主版本.次版本.修订号+构建号
例如：1.0.0+1, 1.0.1+2, 2.0.0+1
```

## 含义
- 修订号+1 = bugfix 或小改进
- 次版本+1 = 新增功能
- 主版本+1 = 重大架构变更
- 构建号 = 每次构建自动递增（本地构建或CI构建各自累计）

## 构建触发方式

### 方式一：本地构建（推荐，服务器网络通畅时）
```bash
bash scripts/local-build.sh
# 自动：版本号+1 → pubspec.yaml更新 → flutter build → APK复制到 /home/admin/xinghai-web/dist/
```

### 方式二：GitHub Actions CI（网络恢复后）
```bash
git add . && git commit -m "fix: xxx" && git push origin master
# 自动触发 CI #N，构建完成后 artifact 在 GitHub Actions 页面下载
```

## 当前状态
- 最新版本：1.0.0+1
- 最新APK下载地址：http://47.103.11.151/app-debug.apk
- 服务器网络问题：dl.google.com（Flutter engine artifacts）间歇性不可达
