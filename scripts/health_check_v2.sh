#!/bin/bash
# CDH 集群服务健康检查脚本 v2.0 - 优化版
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# date: 2025-11-12

# 加载输出格式化库
PROJECT_DIR=/root/setup_cdh_cluster
source "$PROJECT_DIR/lib/output_formatter.sh"

# 配置
MYSQL_PASSWORD="Cloudera!20200801"
CHECK_PASSED=0
CHECK_FAILED=0
CHECK_WARNING=0

# ==========================================
# 检查函数
# ==========================================

check_service() {
    local service_name=$1
    local service_display=$2
    
    if systemctl is-active $service_name >/dev/null 2>&1; then
        print_status "$service_display" "ok" "运行中"
        ((CHECK_PASSED++))
        return 0
    else
        print_status "$service_display" "fail" "未运行"
        ((CHECK_FAILED++))
        return 1
    fi
}

check_port() {
    local port=$1
    local service=$2
    
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        local pid=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $NF}' | head -1)
        print_status "$service (端口 $port)" "ok" "$pid"
        ((CHECK_PASSED++))
        return 0
    else
        print_status "$service (端口 $port)" "fail" "未监听"
        ((CHECK_FAILED++))
        return 1
    fi
}

check_mysql_connection() {
    if mysql -uroot -p"$MYSQL_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
        print_status "MySQL 连接" "ok" "连接正常"
        ((CHECK_PASSED++))
        return 0
    else
        print_status "MySQL 连接" "fail" "连接失败"
        ((CHECK_FAILED++))
        return 1
    fi
}

check_disk_space() {
    local path=$1
    local warn_threshold=${2:-80}
    
    local usage=$(df -h "$path" | tail -1 | awk '{print $(NF-1)}' | sed 's/%//')
    
    if [ "$usage" -lt "$warn_threshold" ]; then
        print_status "$path 磁盘空间" "ok" "使用率 ${usage}%"
        ((CHECK_PASSED++))
    elif [ "$usage" -lt 90 ]; then
        print_status "$path 磁盘空间" "warn" "使用率 ${usage}%"
        ((CHECK_WARNING++))
    else
        print_status "$path 磁盘空间" "fail" "使用率 ${usage}% (危险)"
        ((CHECK_FAILED++))
    fi
}

check_node_connectivity() {
    local node=$1
    
    if ping -c 1 -W 2 "$node" >/dev/null 2>&1; then
        if ssh -o ConnectTimeout=5 -o BatchMode=yes "$node" "exit" >/dev/null 2>&1; then
            print_status "$node" "ok" "网络正常，SSH 可连接"
            ((CHECK_PASSED++))
        else
            print_status "$node" "warn" "网络正常，SSH 需要密码"
            ((CHECK_WARNING++))
        fi
    else
        print_status "$node" "fail" "网络不通"
        ((CHECK_FAILED++))
    fi
}

check_process() {
    local process_name=$1
    local display_name=$2
    
    if pgrep -f "$process_name" >/dev/null 2>&1; then
        local count=$(pgrep -f "$process_name" | wc -l)
        print_status "$display_name" "ok" "$count 个进程"
        ((CHECK_PASSED++))
    else
        print_status "$display_name" "fail" "未运行"
        ((CHECK_FAILED++))
    fi
}

# ==========================================
# 主检查流程
# ==========================================

main() {
    print_banner "CDH 集群健康检查" "全面检查集群状态" "RaynLiu"
    
    # 1. 检查系统服务
    print_header "系统服务状态"
    check_service "mysqld" "MySQL 服务"
    check_service "httpd" "httpd 服务"
    check_service "cloudera-scm-server" "CM Server 服务"
    check_service "cloudera-scm-agent" "CM Agent 服务"
    
    # 2. 检查端口监听
    print_header "端口监听状态"
    check_port 3306 "MySQL"
    check_port 80 "httpd"
    check_port 7180 "CM Server Web"
    check_port 7182 "CM Agent"
    
    # 3. 检查 MySQL 连接
    print_header "数据库连接"
    check_mysql_connection
    
    # 4. 检查磁盘空间
    print_header "磁盘空间"
    check_disk_space "/" 80
    check_disk_space "/opt" 80
    check_disk_space "/var" 80
    
    # 5. 检查节点连通性
    print_header "集群节点"
    check_node_connectivity "node01"
    check_node_connectivity "node02"
    check_node_connectivity "node03"
    
    # 6. 检查关键进程
    print_header "关键进程"
    check_process "cloudera-scm-server" "CM Server 进程"
    check_process "cloudera-scm-agent" "CM Agent 进程"
    check_process "mysqld" "MySQL 进程"
    check_process "httpd" "httpd 进程"
    
    # 显示汇总
    print_header "检查汇总"
    
    echo ""
    print_table_row "检查项" "结果" "数量"
    print_table_header
    print_table_row "✓ 通过" "${GREEN}正常${NC}" "$CHECK_PASSED"
    print_table_row "⚠ 警告" "${YELLOW}需注意${NC}" "$CHECK_WARNING"
    print_table_row "✗ 失败" "${RED}异常${NC}" "$CHECK_FAILED"
    print_single_line
    
    local total=$((CHECK_PASSED + CHECK_WARNING + CHECK_FAILED))
    local pass_rate=$((CHECK_PASSED * 100 / total))
    
    echo ""
    if [ $CHECK_FAILED -eq 0 ] && [ $CHECK_WARNING -eq 0 ]; then
        print_success_header "健康检查完成 - 集群状态良好 (${pass_rate}%)"
        echo -e "  ${GREEN}所有检查项均通过！${NC}"
        echo ""
        return 0
    elif [ $CHECK_FAILED -eq 0 ]; then
        print_warning_header "健康检查完成 - 存在警告项 (${pass_rate}%)"
        echo -e "  ${YELLOW}有 $CHECK_WARNING 项需要注意${NC}"
        echo ""
        return 0
    else
        print_error_header "健康检查完成 - 发现问题 (${pass_rate}%)"
        echo -e "  ${RED}有 $CHECK_FAILED 项检查失败${NC}"
        echo ""
        echo "建议操作："
        echo "  1. 查看详细日志: make logs"
        echo "  2. 检查服务状态: make status"
        echo "  3. 重启服务: make restart-services"
        echo ""
        return 1
    fi
}

# 运行检查
main
