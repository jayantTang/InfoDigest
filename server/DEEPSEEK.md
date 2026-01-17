# DeepSeek API 配置说明

DeepSeek API 集成的详细文档已移至项目统一文档目录。

## 📚 完整文档

请查看 **[DeepSeek集成文档](../docs/deepseek-integration.md)** 获取完整的：
- 为什么选择DeepSeek
- 当前配置说明
- API调用示例
- 定价对比
- 常见问题

## 🚀 快速开始

项目已默认配置DeepSeek API，直接启动服务器即可使用：

```bash
cd server
npm install
npm run migrate
npm run dev
```

## 📖 相关文档

- **[DeepSeek集成文档](../docs/deepseek-integration.md)** - 完整的LLM集成文档
- **[服务器开发指南](../docs/server-development.md)** - 服务器端完整文档
- **[主README](../README.md)** - 项目总体介绍

## ⚙️ 配置

环境变量配置位于 `.env` 文件：

```env
LLM_PROVIDER=deepseek
LLM_MODEL=deepseek-chat
DEEPSEEK_API_KEY=your_deepseek_api_key
```

参考模板：`.env.example`
