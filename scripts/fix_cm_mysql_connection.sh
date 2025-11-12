#!/bin/bash
# CM Server MySQL 连接修复脚本
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

echo "=========================================="
echo "  CM Server MySQL 连接修复工具"
echo "  Copyright © 2025 RaynLiu"
echo "=========================================="
echo ""

# 步骤 1: 检查 MySQL 状态
log_info "步骤 1/5: 检查 MySQL 服务状态..."
if systemctl is-active mysqld >/dev/null 2>&1; then
    log_info "✓ MySQL 正在运行"
else
    log_error "MySQL 未运行，请先启动 MySQL"
    echo "  systemctl start mysqld"
    exit 1
fi

# 步骤 2: 验证 MySQL 连接
log_info "步骤 2/5: 验证 MySQL 连接..."
MYSQL_PASSWORD="Cloudera!20200801"
if mysql -uroot -p"${MYSQL_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; then
    log_info "✓ MySQL 连接正常"
else
    log_error "无法连接 MySQL，请检查密码"
    echo "  当前使用密码: ${MYSQL_PASSWORD}"
    echo "  如需重置密码: bash /root/setup_cdh_cluster/scripts/reset_mysql_password.sh"
    exit 1
fi

# 步骤 3: 检查 CM 数据库
log_info "步骤 3/5: 检查 CM 数据库..."
if mysql -uroot -p"${MYSQL_PASSWORD}" -e "USE scm; SELECT COUNT(*) FROM ROLES;" >/dev/null 2>&1; then
    log_info "✓ CM 数据库存在"
else
    log_warn "CM 数据库可能未正确初始化"
fi

# 步骤 4: 重启 CM Server
log_info "步骤 4/5: 重启 CM Server..."
systemctl stop cloudera-scm-server
sleep 3

log_info "清理旧的日志..."
# 备份当前日志
if [ -f /var/log/cloudera-scm-server/cloudera-scm-server.log ]; then
    cp /var/log/cloudera-scm-server/cloudera-scm-server.log \
       /var/log/cloudera-scm-server/cloudera-scm-server.log.backup.$(date +%Y%m%d_%H%M%S)
fi

log_info "启动 CM Server..."
systemctl start cloudera-scm-server

# 步骤 5: 监控启动日志
log_info "步骤 5/5: 监控启动日志（等待60秒）..."
echo ""
log_info "正在检查数据库连接..."

WAIT_TIME=60
SUCCESS=false

for i in $(seq 1 $WAIT_TIME); do
    sleep 1
    
    # 检查启动成功
    if journalctl -u cloudera-scm-server -n 50 --no-pager | grep -q "Started Jetty server"; then
        log_info "✓ CM Server 启动成功！"
        SUCCESS=true
        break
    fi
    
    # 检查数据库连接错误
    if journalctl -u cloudera-scm-server -n 10 --no-pager | grep -qi "Communications link failure"; then
        log_error "仍然存在数据库连接错误"
        break
    fi
    
    # 显示进度
    if [ $((i % 10)) -eq 0 ]; then
        echo -n "."
    fi
done

echo ""
echo ""
echo "=========================================="

if [ "$SUCCESS" = true ]; then
    log_info "✓ 修复成功！"
    echo "=========================================="
    echo ""
    log_info "CM Server 已成功连接到 MySQL"
    echo ""
    log_info "访问 CM Web 界面:"
    echo "  http://node01:7180"
    echo "  用户名: admin"
    echo "  密码: admin"
    echo ""
    log_info "查看实时日志:"
    echo "  tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log"
    echo ""
else
    log_warn "启动中，请稍候..."
    echo "=========================================="
    echo ""
    log_info "CM Server 正在启动（这可能需要几分钟）"
    echo ""
    log_info "查看启动日志:"
    echo "  tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log"
    echo ""
    log_info "检查服务状态:"
    echo "  systemctl status cloudera-scm-server"
    echo ""
    log_info "如果仍有问题，查看错误日志:"
    echo "  journalctl -u cloudera-scm-server -n 100 | grep -i error"
    echo ""
fi

exit 0
