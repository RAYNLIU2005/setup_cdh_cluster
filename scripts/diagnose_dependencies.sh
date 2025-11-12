#!/bin/bash
# CDH 集群服务依赖关系诊断工具
# Copyright © 2025 RaynLiu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

log_title() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

get_service_start_time() {
    local service=$1
    # 使用 LANG=C 获取英文格式的时间
    local start_time=$(LANG=C systemctl show $service -p ActiveEnterTimestamp --value 2>/dev/null | head -n1)
    
    # 如果为空或无效，尝试不使用 --value
    if [ -z "$start_time" ] || [ "$start_time" = "n/a" ]; then
        start_time=$(LANG=C systemctl show $service -p ActiveEnterTimestamp 2>/dev/null | cut -d= -f2)
    fi
    
    echo "$start_time"
}

get_service_start_timestamp() {
    local service=$1
    local start_time=$(get_service_start_time $service)
    if [ -n "$start_time" ] && [ "$start_time" != "n/a" ]; then
        date -d "$start_time" +%s 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

format_uptime() {
    local start_time=$1
    if [ -z "$start_time" ] || [ "$start_time" = "未知" ]; then
        echo "未运行"
        return
    fi
    
    local now=$(date +%s)
    # 使用 LANG=C 避免中文日期解析问题
    local start_ts=$(LANG=C date -d "$start_time" +%s 2>/dev/null)
    if [ -z "$start_ts" ] || [ "$start_ts" = "0" ]; then
        echo "已运行（无法计算时长）"
        return
    fi
    
    local uptime=$((now - start_ts))
    local hours=$((uptime / 3600))
    local minutes=$(((uptime % 3600) / 60))
    local seconds=$((uptime % 60))
    
    if [ $hours -gt 0 ]; then
        echo "${hours}小时${minutes}分钟"
    elif [ $minutes -gt 0 ]; then
        echo "${minutes}分钟${seconds}秒"
    else
        echo "${seconds}秒"
    fi
}

echo "=========================================="
echo "  CDH 集群服务依赖诊断工具"
echo "  Copyright © 2025 RaynLiu"
echo "=========================================="
echo ""
echo "诊断时间: $(date '+%Y-%m-%d %H:%M:%S')"

log_title "服务运行时间分析"

# 检查各服务
SERVICES=("mysqld" "httpd" "cloudera-scm-server" "cloudera-scm-agent")
ISSUES=0

for service in "${SERVICES[@]}"; do
    if systemctl is-active $service >/dev/null 2>&1; then
        start_time=$(get_service_start_time $service)
        if [ -z "$start_time" ] || [ "$start_time" = "n/a" ]; then
            # 如果无法获取启动时间，使用 ps 命令
            pid=$(systemctl show $service -p MainPID --value 2>/dev/null)
            if [ -n "$pid" ] && [ "$pid" != "0" ]; then
                start_time=$(ps -p $pid -o lstart= 2>/dev/null)
            fi
        fi
        uptime=$(format_uptime "$start_time")
        echo -e "${GREEN}[✓]${NC} $service"
        echo "    启动时间: ${start_time:-未知}"
        echo "    运行时长: $uptime"
    else
        echo -e "${RED}[✗]${NC} $service (未运行)"
        ((ISSUES++))
    fi
    echo ""
done

log_title "服务依赖关系检查"

echo "正确的启动顺序应为:"
echo -e "  1. ${CYAN}mysqld${NC}         (MySQL 数据库)"
echo -e "  2. ${CYAN}httpd${NC}          (本地 YUM 源)"
echo -e "  3. ${CYAN}cloudera-scm-server${NC} (CM Server，依赖 MySQL)"
echo -e "  4. ${CYAN}cloudera-scm-agent${NC}  (CM Agent，依赖 CM Server)"
echo ""

# 分析启动顺序
mysql_ts=$(get_service_start_timestamp mysqld)
httpd_ts=$(get_service_start_timestamp httpd)
cm_server_ts=$(get_service_start_timestamp cloudera-scm-server)
cm_agent_ts=$(get_service_start_timestamp cloudera-scm-agent)

echo "实际启动顺序分析:"
echo ""

# MySQL vs CM Server
if [ "$mysql_ts" -gt 0 ] && [ "$cm_server_ts" -gt 0 ]; then
    time_diff=$((cm_server_ts - mysql_ts))
    if [ $time_diff -gt 5 ]; then
        log_info "✓ MySQL 在 CM Server 之前启动（间隔 ${time_diff} 秒）"
    elif [ $time_diff -ge 0 ] && [ $time_diff -le 5 ]; then
        log_warn "⚠ MySQL 和 CM Server 启动时间太接近（间隔 ${time_diff} 秒）"
        echo "  可能导致 CM Server 连接失败，建议重启修复"
        ((ISSUES++))
    else
        log_error "✗ CM Server 在 MySQL 之前启动（早 $((mysql_ts - cm_server_ts)) 秒）"
        echo "  这会导致 'Communications link failure' 错误！"
        ((ISSUES++))
    fi
else
    log_warn "⚠ 无法比较 MySQL 和 CM Server 启动顺序"
fi

echo ""

# httpd vs others
if [ "$httpd_ts" -gt 0 ]; then
    if [ "$cm_server_ts" -gt 0 ] && [ $((cm_server_ts - httpd_ts)) -gt 0 ]; then
        log_info "✓ httpd 在 CM Server 之前启动"
    fi
    if [ "$cm_agent_ts" -gt 0 ] && [ $((cm_agent_ts - httpd_ts)) -gt 0 ]; then
        log_info "✓ httpd 在 CM Agent 之前启动"
    fi
fi

echo ""

# CM Server vs CM Agent
if [ "$cm_server_ts" -gt 0 ] && [ "$cm_agent_ts" -gt 0 ]; then
    time_diff=$((cm_agent_ts - cm_server_ts))
    if [ $time_diff -gt 0 ]; then
        log_info "✓ CM Server 在 CM Agent 之前启动（间隔 ${time_diff} 秒）"
    else
        log_warn "⚠ CM Agent 在 CM Server 之前启动"
        ((ISSUES++))
    fi
fi

log_title "错误日志分析"

# CM Server 错误
if [ -f /var/log/cloudera-scm-server/cloudera-scm-server.log ]; then
    log_info "检查 CM Server 日志（本次启动后）..."
    
    # 使用 journalctl 只检查当前启动后的日志
    if command -v journalctl >/dev/null 2>&1; then
        # 检查 MySQL 连接错误（仅本次启动）
        mysql_errors=$(journalctl -u cloudera-scm-server --since "$(systemctl show cloudera-scm-server -p ActiveEnterTimestamp --value 2>/dev/null || echo '10 minutes ago')" --no-pager 2>/dev/null | grep -i "Communications link failure" | tail -n 1)
        if [ -n "$mysql_errors" ]; then
            log_error "发现 MySQL 连接错误（本次启动）:"
            echo "$mysql_errors" | head -n 1
            echo ""
            echo "  原因: CM Server 启动时 MySQL 未就绪"
            echo "  修复: bash scripts/fix_cm_mysql_connection.sh"
            ((ISSUES++))
        else
            log_info "✓ 本次启动未发现 MySQL 连接错误"
        fi
        
        echo ""
        
        # 检查其他常见错误（仅本次启动）
        recent_errors=$(journalctl -u cloudera-scm-server --since "$(systemctl show cloudera-scm-server -p ActiveEnterTimestamp --value 2>/dev/null || echo '10 minutes ago')" --no-pager 2>/dev/null | grep -i "ERROR" | grep -v "Communications link failure" | tail -n 3)
        if [ -n "$recent_errors" ]; then
            log_warn "发现其他错误（最近 3 条）:"
            echo "$recent_errors"
        fi
    else
        # 降级到文件检查
        log_warn "无 journalctl，检查日志文件..."
        mysql_errors=$(grep -i "Communications link failure" /var/log/cloudera-scm-server/cloudera-scm-server.log | tail -n 1)
        if [ -n "$mysql_errors" ]; then
            log_warn "发现历史 MySQL 连接错误（可能已修复）"
            echo "  提示: 如果服务当前正常运行，可忽略历史错误"
        else
            log_info "✓ 未发现 MySQL 连接错误"
        fi
    fi
fi

log_title "端口监听检查"

# 检查关键端口
PORTS=("3306:MySQL" "80:httpd" "7180:CM_Web" "7182:CM_Agent")

for port_info in "${PORTS[@]}"; do
    IFS=':' read -r port service <<< "$port_info"
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        log_info "✓ 端口 $port ($service) 正在监听"
    else
        log_error "✗ 端口 $port ($service) 未监听"
        ((ISSUES++))
    fi
done

log_title "MySQL 连接测试"

MYSQL_PASSWORD="Cloudera!20200801"

if mysql -uroot -p"$MYSQL_PASSWORD" -e "SELECT VERSION();" >/dev/null 2>&1; then
    mysql_version=$(mysql -uroot -p"$MYSQL_PASSWORD" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
    log_info "✓ MySQL 连接成功"
    echo "    版本: $mysql_version"
    
    # 检查 SCM 数据库
    if mysql -uroot -p"$MYSQL_PASSWORD" -e "USE scm; SHOW TABLES;" >/dev/null 2>&1; then
        table_count=$(mysql -uroot -p"$MYSQL_PASSWORD" -e "USE scm; SHOW TABLES;" 2>/dev/null | wc -l)
        log_info "✓ SCM 数据库存在（$((table_count - 1)) 个表）"
    else
        log_error "✗ SCM 数据库不存在或无法访问"
        ((ISSUES++))
    fi
else
    log_error "✗ MySQL 连接失败"
    echo "    修复: bash scripts/reset_mysql_password.sh"
    ((ISSUES++))
fi

log_title "系统资源检查"

# 内存
total_mem=$(free -m | awk '/^Mem:/{print $2}')
used_mem=$(free -m | awk '/^Mem:/{print $3}')
mem_percent=$((used_mem * 100 / total_mem))

echo "内存使用: ${used_mem}MB / ${total_mem}MB (${mem_percent}%)"
if [ $mem_percent -gt 90 ]; then
    log_error "✗ 内存使用率过高！"
    ((ISSUES++))
elif [ $mem_percent -gt 80 ]; then
    log_warn "⚠ 内存使用率较高"
else
    log_info "✓ 内存使用正常"
fi

# 磁盘
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
echo "磁盘使用: ${disk_usage}%"
if [ $disk_usage -gt 90 ]; then
    log_error "✗ 磁盘空间不足！"
    ((ISSUES++))
elif [ $disk_usage -gt 80 ]; then
    log_warn "⚠ 磁盘空间较少"
else
    log_info "✓ 磁盘空间充足"
fi

log_title "诊断总结"

echo ""
echo "发现问题: $ISSUES 个"
echo ""

if [ $ISSUES -eq 0 ]; then
    log_info "✓ 系统状态良好，所有服务依赖关系正确"
    echo ""
    echo "CM Web 界面: http://$(hostname):7180"
    echo ""
elif [ $ISSUES -le 2 ]; then
    log_warn "⚠ 发现少量问题，建议修复"
    echo ""
    echo "常用修复命令:"
    echo "  健康检查:          bash scripts/health_check.sh"
    echo "  重置 MySQL:        bash scripts/reset_mysql_password.sh"
    echo "  修复 CM 连接:      bash scripts/fix_cm_mysql_connection.sh"
    echo "  重启服务:          bash scripts/restart_services.sh"
    echo ""
else
    log_error "✗ 发现多个严重问题"
    echo ""
    echo "建议执行:"
    echo "  1. 检查日志:       tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log"
    echo "  2. 运行健康检查:   bash scripts/health_check.sh"
    echo "  3. 按顺序重启:     bash scripts/restart_services.sh"
    echo ""
fi

exit $ISSUES
