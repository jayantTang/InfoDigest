# InfoDigest 服务器脚本目录

此目录包含Node.js服务器开发、测试和维护的脚本。

## 脚本列表

### 服务器管理
- **start-server.sh** - 启动开发服务器
- **stop-server.sh** - 停止服务器
- **restart-server.sh** - 重启服务器

### 测试工具
- **test-api.sh** - 测试API端点
- **test-push.sh** - 发送测试推送通知

### 数据库工具
- **db-shell.sh** - 打开PostgreSQL数据库shell

## 使用说明

### 启动服务器

```bash
# 在server目录下运行
./scripts/start-server.sh
```

该脚本会：
1. 检查Node.js版本
2. 安装依赖（如果需要）
3. 初始化数据库（如果需要）
4. 启动开发服务器

### 停止服务器

```bash
./scripts/stop-server.sh
```

### 重启服务器

```bash
./scripts/restart-server.sh
```

### 测试API

```bash
./scripts/test-api.sh
```

测试所有主要API端点，显示彩色输出结果。

### 测试推送通知

```bash
./scripts/test-push.sh
```

向所有注册的设备发送测试推送。

### 数据库操作

```bash
# 打开数据库shell
./scripts/db-shell.sh

# 在数据库shell中
\dt                          # 查看所有表
SELECT * FROM devices;        # 查看设备
SELECT * FROM messages;       # 查看消息
```

## 相关文档

- **[服务器开发指南](../../docs/server-development.md)** - 完整的服务器文档
- **[DeepSeek集成文档](../../docs/deepseek-integration.md)** - LLM配置
- **[主README](../../README.md)** - 项目总体介绍

## 环境配置

确保在运行脚本前已配置 `.env` 文件：

```bash
# 复制示例配置
cp .env.example .env

# 编辑配置
vim .env
```
