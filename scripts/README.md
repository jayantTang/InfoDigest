# Scripts 目录

此目录包含项目开发、构建和部署的所有脚本。

## 脚本列表

### 构建和部署

- `build-ios.sh` - 构建iOS应用并安装到iPhone
- `start-server.sh` - 启动开发服务器
- `stop-server.sh` - 停止服务器
- `restart-server.sh` - 重启服务器

### 开发工具

- `test-push.sh` - 发送测试推送通知
- `test-api.sh` - 测试API端点
- `db-shell.sh` - 打开数据库shell

### 部署脚本

- `deploy-railway.sh` - 部署到Railway
- `deploy-render.sh` - 部署到Render

## 使用方法

所有脚本都应该从项目根目录运行：

```bash
# 构建
./scripts/build-ios.sh

# 启动服务器
./scripts/start-server.sh

# 测试推送
./scripts/test-push.sh
```

## 添加新脚本

1. 将脚本放在 `scripts/` 目录
2. 添加执行权限：`chmod +x scripts/your-script.sh`
3. 更新此README
