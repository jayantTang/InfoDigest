#!/bin/bash

# 部署前检查脚本
# 验证所有必需的配置是否正确设置

set -e

echo "🔍 InfoDigest 部署前检查"
echo "========================="
echo ""

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass=0
check_fail=0

# 检查函数
check_env() {
  local var_name=$1
  local var_value=${!1}

  if [ -z "$var_value" ]; then
    echo -e "${RED}❌${NC} $var_name 未设置"
    ((check_fail++))
    return 1
  else
    echo -e "${GREEN}✅${NC} $var_name 已设置"
    ((check_pass++))
    return 0
  fi
}

check_warning() {
  local var_name=$1
  local var_value=${!1}

  if [ -z "$var_value" ] || [ "$var_value" = "your_*" ] || [ "$var_value" = "xxx" ]; then
    echo -e "${YELLOW}⚠️ ${NC} $var_name 需要配置"
    ((check_fail++))
    return 1
  else
    echo -e "${GREEN}✅${NC} $var_name 已配置"
    ((check_pass++))
    return 0
  fi
}

echo "📋 环境变量检查"
echo "----------------"

# 加载 .env 文件（过滤注释和空行）
if [ -f .env ]; then
  while IFS='=' read -r key value; do
    # 跳过注释和空行
    [[ $key =~ ^#.*$ ]] && continue
    [[ -z $key ]] && continue
    # 移除值中的注释和引号
    value=$(echo "$value" | sed 's/#.*$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '"'"'"'')
    export "$key=$value"
  done < <(grep '=' .env | grep -v '^#')
else
  echo -e "${RED}❌ .env 文件不存在${NC}"
  exit 1
fi

# 必需的环境变量
check_env "NODE_ENV"
check_env "PORT"
check_env "DB_HOST"
check_env "DB_NAME"
check_env "DB_USER"

echo ""
echo "🔑 API 密钥检查"
echo "----------------"

check_warning "NEWS_API_KEY"
check_warning "DEEPSEEK_API_KEY"
check_warning "LLM_PROVIDER"

echo ""
echo "🔒 安全配置检查"
echo "----------------"

check_warning "ADMIN_API_KEYS"
check_warning "JWT_SECRET"

echo ""
echo "📱 APNs 配置检查"
echo "----------------"

if [ -z "$APNS_KEY_ID" ] || [ "$APNS_KEY_ID" = "your_key_id" ]; then
  echo -e "${YELLOW}⚠️ ${NC} APNS_KEY_ID 未配置（推送功能需要）"
else
  echo -e "${GREEN}✅${NC} APNS_KEY_ID 已配置"
fi

if [ -z "$APNS_TEAM_ID" ] || [ "$APNS_TEAM_ID" = "your_team_id" ]; then
  echo -e "${YELLOW}⚠️ ${NC} APNS_TEAM_ID 未配置（推送功能需要）"
else
  echo -e "${GREEN}✅${NC} APNS_TEAM_ID 已配置"
fi

# 检查证书文件
if [ -f "$APNS_KEY_PATH" ]; then
  echo -e "${GREEN}✅${NC} APNs 证书文件存在"
  ((check_pass++))
else
  echo -e "${YELLOW}⚠️ ${NC} APNs 证书文件不存在: $APNS_KEY_PATH"
  ((check_fail++))
fi

echo ""
echo "📦 依赖检查"
echo "----------------"

if [ -d "node_modules" ]; then
  echo -e "${GREEN}✅${NC} node_modules 已安装"
  ((check_pass++))
else
  echo -e "${RED}❌${NC} node_modules 未安装，请运行 'npm install'"
  ((check_fail++))
fi

echo ""
echo "🗄️  数据库检查"
echo "----------------"

if command -v psql &> /dev/null; then
  echo -e "${GREEN}✅${NC} PostgreSQL 客户端已安装"
  ((check_pass++))

  # 尝试连接数据库
  if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT 1" &> /dev/null; then
    echo -e "${GREEN}✅${NC} 数据库连接成功"
    ((check_pass++))

    # 检查表是否存在
    TABLE_COUNT=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'")
    if [ "$TABLE_COUNT" -gt 0 ]; then
      echo -e "${GREEN}✅${NC} 数据库表已初始化 ($TABLE_COUNT 个表)"
      ((check_pass++))
    else
      echo -e "${YELLOW}⚠️ ${NC} 数据库表未初始化，请运行 'npm run migrate'"
      ((check_fail++))
    fi
  else
    echo -e "${RED}❌${NC} 数据库连接失败"
    ((check_fail++))
  fi
else
  echo -e "${YELLOW}⚠️ ${NC} PostgreSQL 客户端未安装（生产环境可能不需要）"
fi

echo ""
echo "📊 检查结果"
echo "========================="
echo -e "${GREEN}通过: $check_pass${NC}"
echo -e "${RED}失败/警告: $check_fail${NC}"

if [ $check_fail -eq 0 ]; then
  echo ""
  echo -e "${GREEN}🎉 所有检查通过！可以开始部署。${NC}"
  exit 0
else
  echo ""
  echo -e "${YELLOW}⚠️  发现 $check_fail 个问题，请在部署前解决。${NC}"
  echo ""
  echo "建议："
  echo "1. 配置缺失的 API 密钥"
  echo "2. 运行 'npm install' 安装依赖"
  echo "3. 运行 'npm run migrate' 初始化数据库"
  echo "4. 配置 APNs 证书（如需推送功能）"
  exit 1
fi
