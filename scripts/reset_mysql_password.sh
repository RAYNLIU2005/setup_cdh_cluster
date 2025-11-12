#!/bin/bash
# MySQL Root 密码重置脚本
# Copyright © 2025 RaynLiu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

NEW_PASSWORD="Cloudera!20200801"
INITIAL_PASSWORD="123456"

echo "=========================================="
echo "  MySQL Root 密码重置工具"
echo "  Copyright © 2025 RaynLiu"
echo "=========================================="
echo ""

log_info "目标密码: ${NEW_PASSWORD}"
echo ""

# 步骤 1: 检查 MySQL 是否运行
log_info "步骤 1/6: 检查 MySQL 服务状态..."
if systemctl is-active mysqld >/dev/null 2>&1; then
    log_info "✓ MySQL 正在运行"
else
    log_warn "MySQL 未运行，尝试启动..."
    systemctl start mysqld
    sleep 3
fi

# 步骤 2: 尝试使用初始密码 123456
log_info "步骤 2/6: 尝试使用初始密码 123456..."
if mysql -uroot -p"${INITIAL_PASSWORD}" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_PASSWORD}'; FLUSH PRIVILEGES;" 2>/dev/null; then
    log_info "✓ 使用初始密码 123456 成功设置新密码"
    RESET_SUCCESS=true
else
    log_warn "初始密码 123456 无效，尝试其他方法..."
    RESET_SUCCESS=false
fi

# 步骤 3: 尝试使用日志中的临时密码
if [ "$RESET_SUCCESS" = false ]; then
    log_info "步骤 3/6: 尝试从日志获取临时密码..."
    TEMP_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log 2>/dev/null | tail -n 1 | grep -oP 'root@localhost: \K.+' || echo "")
    
    if [ -n "$TEMP_PASSWORD" ]; then
        log_info "找到临时密码: ${TEMP_PASSWORD:0:3}***"
        if mysql -uroot -p"${TEMP_PASSWORD}" --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_PASSWORD}'; FLUSH PRIVILEGES;" 2>/dev/null; then
            log_info "✓ 使用临时密码成功设置新密码"
            RESET_SUCCESS=true
        else
            log_warn "临时密码无效"
        fi
    else
        log_warn "未找到临时密码"
    fi
fi

# 步骤 4: 尝试无密码方式
if [ "$RESET_SUCCESS" = false ]; then
    log_info "步骤 4/6: 尝试无密码连接..."
    if mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_PASSWORD}'; FLUSH PRIVILEGES;" 2>/dev/null; then
        log_info "✓ 无密码方式成功设置新密码"
        RESET_SUCCESS=true
    else
        log_warn "无密码方式失败"
    fi
fi

# 步骤 5: 使用安全模式强制重置
if [ "$RESET_SUCCESS" = false ]; then
    log_info "步骤 5/6: 使用安全模式强制重置..."
    
    # 停止 MySQL
    systemctl stop mysqld 2>/dev/null || true
    sleep 2
    
    # 杀死残留进程
    pkill -9 mysqld 2>/dev/null || true
    sleep 1
    
    # 以安全模式启动
    log_info "以安全模式启动 MySQL（跳过授权表）..."
    mysqld_safe --skip-grant-tables --skip-networking &
    MYSQLD_PID=$!
    
    log_info "等待 MySQL 启动..."
    sleep 5
    
    # 重置密码
    log_info "执行密码重置..."
    mysql -uroot << EOF 2>/dev/null
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_PASSWORD}';
FLUSH PRIVILEGES;
EOF
    
    # 停止安全模式
    log_info "停止安全模式..."
    kill $MYSQLD_PID 2>/dev/null || true
    pkill -9 mysqld_safe 2>/dev/null || true
    sleep 2
    
    # 正常启动
    log_info "正常启动 MySQL..."
    systemctl start mysqld
    sleep 3
    
    RESET_SUCCESS=true
fi

# 步骤 6: 验证新密码
log_info "步骤 6/6: 验证新密码..."
if mysql -uroot -p"${NEW_PASSWORD}" -e "SELECT 'SUCCESS' as status;" 2>/dev/null | grep -q SUCCESS; then
    echo ""
    echo "=========================================="
    log_info "  ✓ 密码重置成功！"
    echo "=========================================="
    echo ""
    echo "新密码: ${NEW_PASSWORD}"
    echo ""
    log_info "现在可以继续部署:"
    echo "  cd /root/setup_cdh_cluster"
    echo "  make deploy"
    echo ""
    
    # 清理提示文件
    rm -f /tmp/mysql_password_fix_needed
    
    exit 0
else
    echo ""
    echo "=========================================="
    log_error "  ✗ 密码重置失败！"
    echo "=========================================="
    echo ""
    log_error "无法使用新密码连接 MySQL"
    echo ""
    echo "请尝试手动重置:"
    echo "  systemctl stop mysqld"
    echo "  mysqld_safe --skip-grant-tables --skip-networking &"
    echo "  sleep 5"
    echo "  mysql -uroot -e \"FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_PASSWORD}'; FLUSH PRIVILEGES;\""
    echo "  pkill mysqld_safe"
    echo "  systemctl start mysqld"
    echo ""
    exit 1
fi
