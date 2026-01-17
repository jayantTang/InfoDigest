# InfoDigest 文档目录

本目录包含 InfoDigest 项目的详细技术文档。

## 文档结构

### iOS 开发
- **[iOS开发指南](./ios-development.md)** - iOS客户端开发、构建和调试指南

### 服务器开发
- **[服务器开发指南](./server-development.md)** - Node.js服务器架构、API和部署指南
- **[DeepSeek集成文档](./deepseek-integration.md)** - LLM服务配置和使用说明

### 项目根文档
- **[主README](../README.md)** - 项目总体介绍和快速开始
- **[CLAUDE.md](../CLAUDE.md)** - Claude AI开发指南

## 快速导航

### 新用户入门
1. 阅读 [主README](../README.md) 了解项目概况
2. 根据你的开发重点选择：
   - iOS开发 → [iOS开发指南](./ios-development.md)
   - 服务器开发 → [服务器开发指南](./server-development.md)

### 常用任务

#### iOS开发
- 构建并安装到设备：查看 [iOS开发指南 - 常用命令](./ios-development.md#常用命令)
- 测试推送通知：查看 [iOS开发指南 - 测试推送](./ios-development.md#测试推送)
- 离线开发模式：查看 [iOS开发指南 - 开发模式](./ios-development.md#开发模式)

#### 服务器开发
- 启动服务器：`cd server && ./scripts/start-server.sh`
- 初始化数据库：`cd server && npm run migrate`
- 查看日志：`tail -f server/logs/combined.log`
- API测试：`cd server && ./scripts/test-api.sh`

#### 数据库管理
- 打开数据库shell：`cd server && ./scripts/db-shell.sh`
- 查看设备：查看 [iOS开发指南 - 数据库检查](./ios-development.md#数据库检查)

### API端点参考

详细的API文档请参考 [服务器开发指南 - API文档](./server-development.md#api文档)。

主要端点：
- `POST /api/devices/register` - 设备注册
- `GET /api/messages` - 获取消息列表
- `GET /api/messages/:id` - 获取消息详情
- `PUT /api/messages/:id/read` - 标记已读
- `POST /api/admin/test-push` - 测试推送
- `POST /api/admin/run-digest` - 手动触发摘要生成

## 技术栈概览

### iOS客户端
- **语言**: Swift
- **框架**: SwiftUI
- **架构**: MVVM
- **最低版本**: iOS 15.0+
- **依赖**: 无第三方库（仅使用Apple框架）

### 服务器
- **运行时**: Node.js 18+
- **框架**: Express.js
- **数据库**: PostgreSQL 14+
- **缓存**: Redis 7+
- **LLM**: DeepSeek API (默认) / OpenAI API
- **推送**: APNs (Apple Push Notification Service)

## 开发工具

### 脚本工具

项目中的脚本按模块组织：

**iOS脚本** (`InfoDigest/scripts/`):
- `build-ios.sh` - 构建iOS应用并安装到设备

**服务器脚本** (`server/scripts/`):
- `start-server.sh` - 启动服务器
- `stop-server.sh` - 停止服务器
- `restart-server.sh` - 重启服务器
- `test-push.sh` - 测试推送通知
- `test-api.sh` - 测试API端点
- `db-shell.sh` - 数据库shell

详见各子目录的 `scripts/README.md` 文件。

## 故障排查

### iOS端问题
查看 [iOS开发指南 - 常见问题](./ios-development.md#常见问题)

### 服务器端问题
查看 [服务器开发指南 - 故障排查](./server-development.md#故障排查)

### API和LLM问题
查看 [DeepSeek集成文档 - 常见问题](./deepseek-integration.md#常见问题)
