#!/bin/bash
# CDH 集群服务健康检查脚本
# Copyright © 2025 RaynLiu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MYSQL_PASSWORD="Cloudera!20200801"
CHECK_PASSED=0
CHECK_FAILED=0

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

check_service() {
    local service_name=$1
    local service_display=$2
    
    if systemctl is-active $service_name >/dev/null 2>&1; then
        log_info "✓ $service_display 运行中"
        ((CHECK_PASSED++))
        return 0
    else
        log_error "✗ $service_display 未运行"
        ((CHECK_FAILED++))
        return 1
    fi
}

check_port() {
    local port=$1
    local service=$2
    
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        log_info "✓ $service 端口 $port 监听中"
        ((CHECK_PASSED++))
        return 0
    else
        log_error "✗ $service 端口 $port 未监听"
        ((CHECK_FAILED++))
        return 1
    fi
}

check_mysql_connection() {
    if mysql -uroot -p"$MYSQL_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
        log_info "✓ MySQL 连接正常"
        ((CHECK_PASSED++))
        
        # 检查 SCM 数据库
        if mysql -uroot -p"$MYSQL_PASSWORD" -e "USE scm; SELECT COUNT(*) FROM ROLES;" >/dev/null 2>&1; then
            log_info "✓ SCM 数据库正常"
            ((CHECK_PASSED++))
        else
            log_warn "⚠ SCM 数据库未初始化或异常"
            ((CHECK_FAILED++))
        fi
        return 0
    else
        log_error "✗ MySQL 连接失败"
        echo "  尝试修复: bash scripts/reset_mysql_password.sh"
        ((CHECK_FAILED++))
        return 1
    fi
}

check_cm_server_logs() {
    if [ -f /var/log/cloudera-scm-server/cloudera-scm-server.log ]; then
        # 检查最近的错误
        local recent_errors=$(tail -n 100 /var/log/cloudera-scm-server/cloudera-scm-server.log | grep -i "ERROR" | tail -n 3)
        
        if echo "$recent_errors" | grep -qi "Communications link failure"; then
            log_error "✗ CM Server MySQL 连接失败"
            echo "  修复命令: bash scripts/fix_cm_mysql_connection.sh"
            ((CHECK_FAILED++))
            return 1
        elif [ -n "$recent_errors" ]; then
            log_warn "⚠ CM Server 有错误日志（非致命）"
            ((CHECK_PASSED++))
            return 0
        else
            log_info "✓ CM Server 日志正常"
            ((CHECK_PASSED++))
            return 0
        fi
    else
        log_warn "⚠ CM Server 日志文件不存在"
        ((CHECK_FAILED++))
        return 1
    fi
}

check_cm_web() {
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:7180 2>/dev/null | grep -q "200\|302"; then
        log_info "✓ CM Web 界面可访问"
        ((CHECK_PASSED++))
        return 0
    else
        log_warn "⚠ CM Web 界面不可访问（可能正在启动）"
        ((CHECK_FAILED++))
        return 1
    fi
}

echo "=========================================="
echo "  CDH 集群健康检查工具"
echo "  Copyright © 2025 RaynLiu"
echo "=========================================="
echo ""
echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ========== Master 节点检查 ==========
if [ "$(hostname)" == "node01" ]; then
    log_title "Master 节点服务检查 (node01)"
    
    echo ""
    echo "--- MySQL 服务 ---"
    check_service mysqld "MySQL Server"
    if [ $? -eq 0 ]; then
        check_port 3306 "MySQL"
        check_mysql_connection
    fi
    
    echo ""
    echo "--- CM Server ---"
    check_service cloudera-scm-server "CM Server"
    if [ $? -eq 0 ]; then
        check_port 7180 "CM Web"
        sleep 1
        check_cm_server_logs
        check_cm_web
    fi
    
    echo ""
    echo "--- httpd 本地 YUM 源 ---"
    check_service httpd "Apache httpd"
    if [ $? -eq 0 ]; then
        check_port 80 "httpd"
    fi
fi

# ========== 所有节点检查 ==========
log_title "CM Agent 检查"
echo ""
check_service cloudera-scm-agent "CM Agent"

# ========== 服务依赖检查 ==========
log_title "服务依赖关系检查"
echo ""

# 检查 MySQL -> CM Server 依赖
if systemctl is-active mysqld >/dev/null 2>&1 && systemctl is-active cloudera-scm-server >/dev/null 2>&1; then
    # 获取启动时间
    mysql_start=$(systemctl show mysqld -p ActiveEnterTimestamp --value 2>/dev/null | head -n1)
    cm_start=$(systemctl show cloudera-scm-server -p ActiveEnterTimestamp --value 2>/dev/null | head -n1)
    
    if [ -n "$mysql_start" ] && [ -n "$cm_start" ]; then
        mysql_ts=$(date -d "$mysql_start" +%s 2>/dev/null)
        cm_ts=$(date -d "$cm_start" +%s 2>/dev/null)
        
        if [ "$mysql_ts" -lt "$cm_ts" ]; then
            log_info "✓ MySQL 在 CM Server 之前启动（正确）"
            ((CHECK_PASSED++))
        else
            log_warn "⚠ CM Server 在 MySQL 之前启动（可能导致连接问题）"
            echo "  修复命令: bash scripts/fix_cm_mysql_connection.sh"
            ((CHECK_FAILED++))
        fi
    fi
fi

# ========== 总结 ==========
echo ""
log_title "健康检查总结"
echo ""
echo "通过: $CHECK_PASSED 项"
echo "失败: $CHECK_FAILED 项"
echo ""

if [ $CHECK_FAILED -eq 0 ]; then
    log_info "✓ 所有检查通过！集群状态健康"
    echo ""
    echo "CM Web 界面: http://$(hostname):7180"
    echo "用户名: admin / 密码: admin"
    echo ""
    exit 0
elif [ $CHECK_FAILED -le 2 ]; then
    log_warn "⚠ 发现 $CHECK_FAILED 个问题，建议修复"
    echo ""
    exit 1
else
    log_error "✗ 发现 $CHECK_FAILED 个严重问题"
    echo ""
    echo "常用修复命令:"
    echo "  重置 MySQL 密码:     bash scripts/reset_mysql_password.sh"
    echo "  修复 CM-MySQL 连接:  bash scripts/fix_cm_mysql_connection.sh"
    echo "  重启所有服务:        bash scripts/restart_services.sh"
    echo ""
    exit 2
fi
