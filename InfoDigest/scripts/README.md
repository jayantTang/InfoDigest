# InfoDigest iOS 脚本目录

此目录包含iOS客户端开发、构建和部署的脚本。

## 脚本列表

### 构建和部署
- **build-ios.sh** - 构建iOS应用并安装到iPhone

## 使用说明

### 构建并安装到设备

```bash
# 在InfoDigest目录下运行
./scripts/build-ios.sh
```

该脚本会：
1. 检查服务器状态
2. 使用xcodebuild编译应用
3. 使用ios-deploy安装到iPhone
4. 如果需要，启动服务器

### 手动构建

如果需要手动构建，使用Xcode：

```bash
open InfoDigest.xcodeproj
```

## 相关文档

- **[iOS开发指南](../../docs/ios-development.md)** - 完整的iOS开发文档
- **[主README](../../README.md)** - 项目总体介绍
