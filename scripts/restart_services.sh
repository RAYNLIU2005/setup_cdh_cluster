#!/bin/bash
# CDH 集群服务重启脚本（按正确顺序）
# Copyright © 2025 RaynLiu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MYSQL_PASSWORD="Cloudera!20200801"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_title() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

echo "=========================================="
echo "  CDH 集群服务重启工具"
echo "  Copyright © 2025 RaynLiu"
echo "=========================================="
echo ""

# 确认操作
read -p "是否要重启所有 CDH 服务？这将短暂中断服务 (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log_info "操作已取消"
    exit 0
fi

echo ""
log_title "步骤 1/4: 停止服务（逆序）"

# 先停止 CM Server 和 Agent
if systemctl is-active cloudera-scm-server >/dev/null 2>&1; then
    log_info "停止 CM Server..."
    systemctl stop cloudera-scm-server
    sleep 2
fi

if systemctl is-active cloudera-scm-agent >/dev/null 2>&1; then
    log_info "停止 CM Agent..."
    systemctl stop cloudera-scm-agent
    sleep 2
fi

# 可选：停止 MySQL（如果需要）
read -p "是否也重启 MySQL？(y/N): " restart_mysql
if [[ "$restart_mysql" =~ ^[Yy]$ ]]; then
    log_info "停止 MySQL..."
    systemctl stop mysqld
    sleep 2
fi

log_title "步骤 2/4: 启动核心服务"

# 按依赖顺序启动
if [[ "$restart_mysql" =~ ^[Yy]$ ]]; then
    log_info "启动 MySQL..."
    systemctl start mysqld
    
    log_info "等待 MySQL 就绪..."
    for i in {1..30}; do
        if mysql -uroot -p"$MYSQL_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
            log_info "✓ MySQL 已就绪"
            break
        fi
        sleep 1
        if [ $i -eq 30 ]; then
            log_error "MySQL 启动超时"
            exit 1
        fi
    done
fi

log_title "步骤 3/4: 启动 CM Server"

log_info "启动 CM Server..."
systemctl start cloudera-scm-server

log_info "等待 CM Server 启动（最多 120 秒）..."
for i in {1..120}; do
    # 检查端口
    if netstat -tuln 2>/dev/null | grep -q ":7180 " || ss -tuln 2>/dev/null | grep -q ":7180 "; then
        log_info "✓ CM Server 端口已监听"
        break
    fi
    
    # 检查错误
    if journalctl -u cloudera-scm-server -n 10 --no-pager | grep -qi "Communications link failure"; then
        log_error "CM Server 启动失败 - MySQL 连接错误"
        echo ""
        echo "尝试修复:"
        echo "  bash scripts/fix_cm_mysql_connection.sh"
        exit 1
    fi
    
    sleep 1
    if [ $((i % 10)) -eq 0 ]; then
        echo -n "."
    fi
done

echo ""
sleep 5

# 验证启动成功
if journalctl -u cloudera-scm-server -n 50 --no-pager | grep -q "Started Jetty server"; then
    log_info "✓ CM Server 启动成功"
else
    log_warn "CM Server 可能还在启动中"
fi

log_title "步骤 4/4: 启动 CM Agent"

log_info "启动 CM Agent..."
systemctl start cloudera-scm-agent

sleep 3

if systemctl is-active cloudera-scm-agent >/dev/null 2>&1; then
    log_info "✓ CM Agent 已启动"
else
    log_error "✗ CM Agent 启动失败"
fi

log_title "服务重启完成"

echo ""
log_info "服务状态:"
echo ""

# MySQL
if systemctl is-active mysqld >/dev/null 2>&1; then
    echo "  [✓] MySQL Server"
else
    echo "  [✗] MySQL Server"
fi

# CM Server
if systemctl is-active cloudera-scm-server >/dev/null 2>&1; then
    echo "  [✓] CM Server"
else
    echo "  [✗] CM Server"
fi

# CM Agent
if systemctl is-active cloudera-scm-agent >/dev/null 2>&1; then
    echo "  [✓] CM Agent"
else
    echo "  [✗] CM Agent"
fi

echo ""
log_info "访问 CM Web 界面:"
echo "  http://$(hostname):7180"
echo "  用户名: admin / 密码: admin"
echo ""

log_info "查看详细状态:"
echo "  bash scripts/health_check.sh"
echo ""

log_info "如有问题，查看日志:"
echo "  tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log"
echo ""

exit 0
