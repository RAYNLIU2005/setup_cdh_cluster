#!/bin/bash
# CDH 部署后检查和修复脚本
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# date: 2025-11-12

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# 检查CM Server启动状态
check_cm_server() {
    log_section "检查 CM Server 启动状态"
    
    local max_wait=300  # 最多等待5分钟
    local waited=0
    local interval=10
    local port_reported=0  # 标记是否已报告端口监听
    
    echo -n "等待 CM Server 启动"
    
    while [ $waited -lt $max_wait ]; do
        # 检查端口
        if netstat -tlnp 2>/dev/null | grep -q ":7180"; then
            # 只在第一次检测到端口时输出
            if [ $port_reported -eq 0 ]; then
                echo ""  # 换行
                log_info "CM Server 端口 7180 已监听"
                echo -n "等待 Jetty 完全启动"
                port_reported=1
            fi
            
            # 检查日志
            if journalctl -u cloudera-scm-server -n 50 --no-pager 2>/dev/null | grep -q "Started Jetty server"; then
                echo ""  # 换行
                log_info "CM Server 已完全启动！"
                return 0
            else
                echo -n "."  # 静默等待，只显示进度点
            fi
        else
            echo -n "."  # 等待端口监听
        fi
        
        sleep $interval
        waited=$((waited + interval))
    done
    
    echo ""  # 换行
    
    log_error "CM Server 启动超时（等待了 ${max_wait} 秒）"
    return 1
}

# 检查服务状态
check_services() {
    log_section "检查关键服务状态"
    
    # MySQL
    if systemctl is-active --quiet mysqld; then
        log_info "MySQL 服务运行正常"
    else
        log_error "MySQL 服务未运行"
        return 1
    fi
    
    # httpd
    if systemctl is-active --quiet httpd; then
        log_info "httpd 服务运行正常"
    else
        log_warn "httpd 服务未运行（本地YUM仓库）"
    fi
    
    # CM Server
    if systemctl is-active --quiet cloudera-scm-server; then
        log_info "CM Server 服务运行正常"
    else
        log_error "CM Server 服务未运行"
        return 1
    fi
    
    # CM Agent
    if systemctl is-active --quiet cloudera-scm-agent; then
        log_info "CM Agent 服务运行正常"
    else
        log_warn "CM Agent 服务未运行"
    fi
}

# 检查MySQL数据库
check_mysql_databases() {
    log_section "检查 MySQL 数据库"
    
    local password="Cloudera!20200801"
    
    # 检查数据库列表
    databases=$(mysql -uroot -p"${password}" -e "SHOW DATABASES;" 2>/dev/null | grep -E "scm|amon|hive|hue|oozie" || echo "")
    
    if [ -n "$databases" ]; then
        log_info "CDH 相关数据库已创建："
        echo "$databases" | while read db; do
            echo "    - $db"
        done
    else
        log_warn "未找到 CDH 相关数据库（可能仍在初始化）"
    fi
    
    # 检查 scm 数据库表（CM Server启动后会创建）
    if mysql -uroot -p"${password}" -e "USE scm; SHOW TABLES;" &>/dev/null; then
        table_count=$(mysql -uroot -p"${password}" -e "USE scm; SHOW TABLES;" 2>/dev/null | wc -l)
        if [ $table_count -gt 1 ]; then
            log_info "scm 数据库表已创建（${table_count} 个表）"
        else
            log_warn "scm 数据库表尚未创建（CM Server 首次启动时会自动创建）"
        fi
    else
        log_warn "无法访问 scm 数据库"
    fi
}

# 检查端口监听
check_ports() {
    log_section "检查端口监听"
    
    check_port() {
        local port=$1
        local service=$2
        
        if netstat -tlnp 2>/dev/null | grep -q ":${port}"; then
            log_info "${service} 端口 ${port} 已监听"
        else
            log_warn "${service} 端口 ${port} 未监听"
        fi
    }
    
    check_port 3306 "MySQL"
    check_port 80 "httpd"
    check_port 7180 "CM Server"
    check_port 7182 "CM Agent"
}

# 检查节点连通性
check_nodes() {
    log_section "检查集群节点连通性"
    
    for node in node01 node02 node03; do
        if ping -c 1 -W 2 $node &>/dev/null; then
            log_info "$node 网络连通"
        else
            log_error "$node 网络不通"
        fi
    done
}

# 显示访问信息
show_access_info() {
    log_section "访问信息"
    
    echo ""
    echo "🌐 Cloudera Manager Web 界面："
    echo "   URL: http://node01:7180"
    echo "   或:  http://192.168.56.151:7180"
    echo ""
    echo "   用户名: admin"
    echo "   密码:   admin"
    echo ""
}

# 显示常见问题
show_common_issues() {
    log_section "部署警告说明"
    
    echo ""
    echo "部署过程中的警告说明（不影响使用）："
    echo ""
    echo "1. ${YELLOW}Python 3.6 弃用警告${NC}"
    echo "   - 状态: ✅ 不影响功能"
    echo "   - 说明: CentOS 7 默认 Python 3.6，库提示即将停止支持"
    echo ""
    echo "2. ${YELLOW}htop 安装失败${NC}"
    echo "   - 状态: ✅ 可选工具，已忽略"
    echo "   - 说明: htop 是监控工具，不影响 CDH 部署"
    echo ""
    echo "3. ${YELLOW}MySQL ROLES 表不存在${NC}"
    echo "   - 状态: ✅ 正常现象"
    echo "   - 说明: CM Server 首次启动时会自动创建这些表"
    echo ""
    echo "4. ${YELLOW}CM Server 启动检查失败${NC}"
    echo "   - 状态: ✅ 需要等待 3-5 分钟"
    echo "   - 说明: CM Server 启动需要时间，本脚本会继续等待"
    echo ""
}

# 主函数
main() {
    echo ""
    echo "=========================================="
    echo "  CDH 部署后检查脚本"
    echo "  Copyright © 2025 RaynLiu"
    echo "=========================================="
    echo ""
    
    # 显示常见问题说明
    show_common_issues
    
    # 检查节点连通性
    check_nodes
    
    # 检查服务状态
    check_services
    
    # 检查端口
    check_ports
    
    # 检查数据库
    check_mysql_databases
    
    # 等待CM Server启动
    echo ""
    echo "等待 CM Server 完全启动..."
    if check_cm_server; then
        log_info "CM Server 启动成功！"
    else
        log_warn "CM Server 启动较慢，请手动检查日志"
        echo "查看日志: tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log"
    fi
    
    # 显示访问信息
    show_access_info
    
    # 最终总结
    log_section "检查完成"
    echo ""
    echo "✅ 部署检查完成！"
    echo ""
    echo "📋 下一步操作："
    echo "   1. 访问 CM Web 界面: http://node01:7180"
    echo "   2. 运行完整测试: make test-full"
    echo "   3. 查看服务状态: make status"
    echo ""
}

# 运行主函数
main
