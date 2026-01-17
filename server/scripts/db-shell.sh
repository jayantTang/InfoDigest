#!/bin/bash

# InfoDigest 数据库Shell脚本

DB_NAME="infodigest"
DB_USER="huiminzhang"

echo "=== InfoDigest 数据库 Shell ==="
echo ""
echo "连接信息："
echo "  数据库: $DB_NAME"
echo "  用户: $DB_USER"
echo ""

# 打开psql
psql -h localhost -U "$DB_USER" -d "$DB_NAME"
