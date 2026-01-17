# InfoDigest Server

服务器端的详细文档已移至项目统一文档目录。

## 📚 完整文档

请查看 **[服务器开发指南](../docs/server-development.md)** 获取完整的：
- 快速开始指南
- API文档
- 部署说明
- 故障排查

## 🚀 快速启动

```bash
# 安装依赖
npm install

# 初始化数据库
npm run migrate

# 启动服务器（开发模式）
npm run dev

# 启动服务器（生产模式）
npm start
```

## 🔧 配置

环境变量配置文件：`.env`

参考模板：`.env.example`

## 📖 相关文档

- **[服务器开发指南](../docs/server-development.md)** - 完整的服务器端文档
- **[DeepSeek集成文档](../docs/deepseek-integration.md)** - LLM服务配置
- **[iOS开发指南](../docs/ios-development.md)** - iOS客户端文档
- **[主README](../README.md)** - 项目总体介绍

## 🔗 有用的脚本

使用项目根目录的 `scripts/` 目录中的脚本：
- `../scripts/start-server.sh` - 启动服务器
- `../scripts/stop-server.sh` - 停止服务器
- `../scripts/restart-server.sh` - 重启服务器
- `../scripts/test-api.sh` - 测试API端点
- `../scripts/test-push.sh` - 测试推送通知
- `../scripts/db-shell.sh` - 打开数据库shell
