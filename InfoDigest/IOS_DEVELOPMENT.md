# iOS开发指南

iOS客户端开发的详细文档已移至项目统一文档目录。

## 📚 完整文档

请查看 **[iOS开发指南](../docs/ios-development.md)** 获取完整的：
- 项目架构说明
- 常用命令
- 配置说明
- 开发模式
- 测试和调试
- 常见问题

## 🚀 快速开始

### 自动构建（推荐）

```bash
# 在项目根目录运行
./scripts/build-ios.sh
```

### 使用Xcode

```bash
# 打开Xcode项目
open InfoDigest.xcodeproj

# 选择您的iPhone设备并点击运行
```

## 📖 相关文档

- **[iOS开发指南](../docs/ios-development.md)** - 完整的iOS开发文档
- **[服务器开发指南](../docs/server-development.md)** - 服务器端文档
- **[主README](../README.md)** - 项目总体介绍

## 🔗 有用的脚本

使用项目根目录的 `scripts/` 目录中的脚本：
- `../scripts/build-ios.sh` - 构建iOS应用并安装到iPhone
- `../scripts/test-push.sh` - 测试推送通知
