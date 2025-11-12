#!/bin/bash
# 集群启停控制脚本（优化版）
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# date: 2025-11-12

# 加载输出格式化库
PROJECT_DIR=/root/setup_cdh_cluster
source "$PROJECT_DIR/lib/output_formatter.sh" 2>/dev/null || {
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
    log_error() { echo -e "${RED}[✗]${NC} $1"; }
    log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
    log_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
    log_step() { echo -e "${BLUE}[→]${NC} $1"; }
}

NODES=("node01" "node02" "node03")

# ==========================================
# 验证 Agent 配置
# ==========================================
verify_agent_config() {
    local node=$1
    
    log_step "验证 $node Agent 配置..."
    
    local server_host=$(ssh $node "grep '^server_host=' /etc/cloudera-scm-agent/config.ini 2>/dev/null | cut -d= -f2" 2>/dev/null)
    
    if [ -z "$server_host" ]; then
        log_warning "$node Agent 配置文件不存在或无法读取"
        return 1
    elif [ "$server_host" != "node01" ]; then
        log_error "$node Agent 配置错误: server_host=$server_host (期望:node01)"
        log_step "自动修复 $node Agent 配置..."
        ssh $node "sed -i 's/^server_host=.*/server_host=node01/' /etc/cloudera-scm-agent/config.ini"
        log_success "$node Agent 配置已修复"
    else
        log_success "$node Agent 配置正确: server_host=$server_host"
    fi
    
    return 0
}

# ==========================================
# 启动服务
# ==========================================
start_cluster() {
    print_header "启动 CDH 集群"
    
    echo "启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # 步骤 1: 验证配置
    print_section "步骤 1/4: 验证 Agent 配置"
    for node in "${NODES[@]}"; do
        verify_agent_config $node
    done
    
    echo ""
    
    # 步骤 2: 启动 Master 节点服务
    print_section "步骤 2/4: 启动 Master 节点服务"
    
    log_step "启动 MySQL..."
    ssh node01 "systemctl start mysqld" 2>/dev/null
    sleep 2
    if ssh node01 "systemctl is-active mysqld" >/dev/null 2>&1; then
        log_success "MySQL 已启动"
    else
        log_error "MySQL 启动失败"
    fi
    
    log_step "启动 httpd..."
    ssh node01 "systemctl start httpd" 2>/dev/null
    if ssh node01 "systemctl is-active httpd" >/dev/null 2>&1; then
        log_success "httpd 已启动"
    else
        log_warning "httpd 启动失败"
    fi
    
    log_step "启动 CM Server..."
    ssh node01 "systemctl start cloudera-scm-server" 2>/dev/null
    if ssh node01 "systemctl is-active cloudera-scm-server" >/dev/null 2>&1; then
        log_success "CM Server 已启动"
    else
        log_error "CM Server 启动失败"
    fi
    
    echo ""
    
    # 步骤 3: 等待 CM Server 完全启动
    print_section "步骤 3/4: 等待 CM Server 启动"
    
    log_step "CM Server 需要约 30-60 秒启动..."
    local wait_time=0
    local max_wait=60
    
    while [ $wait_time -lt $max_wait ]; do
        if ssh node01 "netstat -tlnp | grep 7180" >/dev/null 2>&1; then
            log_success "CM Server 启动完成（耗时: ${wait_time}秒）"
            break
        fi
        sleep 5
        ((wait_time+=5))
        echo -n "."
    done
    
    if [ $wait_time -ge $max_wait ]; then
        log_warning "CM Server 启动超时，请检查日志"
    fi
    
    echo ""
    echo ""
    
    # 步骤 4: 启动所有 Agent
    print_section "步骤 4/4: 启动所有节点 Agent"
    
    local success_count=0
    for node in "${NODES[@]}"; do
        log_step "启动 $node Agent..."
        ssh $node "systemctl start cloudera-scm-agent" 2>/dev/null
        sleep 2
        
        if ssh $node "systemctl is-active cloudera-scm-agent" >/dev/null 2>&1; then
            log_success "$node Agent 已启动"
            ((success_count++))
        else
            log_error "$node Agent 启动失败"
        fi
    done
    
    echo ""
    
    # 汇总
    print_section "启动完成汇总"
    
    echo "成功启动的节点: $success_count/${#NODES[@]}"
    echo ""
    echo "🌐 Cloudera Manager Web 界面:"
    echo "  URL:  http://node01:7180"
    echo "  或:   http://192.168.56.151:7180"
    echo ""
    echo "  用户名: admin"
    echo "  密码:   admin"
    echo ""
    
    if [ $success_count -eq ${#NODES[@]} ]; then
        log_success "集群启动成功！"
    else
        log_warning "部分节点启动失败，请检查日志"
    fi
    
    echo ""
}

# ==========================================
# 停止服务
# ==========================================
stop_cluster() {
    print_header "停止 CDH 集群"
    
    echo "停止时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # 步骤 1: 停止所有 Agent
    print_section "步骤 1/2: 停止所有节点 Agent"
    
    local success_count=0
    for node in "${NODES[@]}"; do
        log_step "停止 $node Agent..."
        ssh $node "systemctl stop cloudera-scm-agent" 2>/dev/null
        sleep 1
        
        if ! ssh $node "systemctl is-active cloudera-scm-agent" >/dev/null 2>&1; then
            log_success "$node Agent 已停止"
            ((success_count++))
        else
            log_warning "$node Agent 仍在运行"
        fi
    done
    
    echo ""
    
    # 步骤 2: 停止 Master 节点服务
    print_section "步骤 2/2: 停止 Master 节点服务"
    
    log_step "停止 CM Server..."
    ssh node01 "systemctl stop cloudera-scm-server" 2>/dev/null
    sleep 2
    if ! ssh node01 "systemctl is-active cloudera-scm-server" >/dev/null 2>&1; then
        log_success "CM Server 已停止"
    else
        log_warning "CM Server 仍在运行"
    fi
    
    log_step "停止 httpd..."
    ssh node01 "systemctl stop httpd" 2>/dev/null
    if ! ssh node01 "systemctl is-active httpd" >/dev/null 2>&1; then
        log_success "httpd 已停止"
    else
        log_warning "httpd 仍在运行"
    fi
    
    log_step "停止 MySQL..."
    ssh node01 "systemctl stop mysqld" 2>/dev/null
    if ! ssh node01 "systemctl is-active mysqld" >/dev/null 2>&1; then
        log_success "MySQL 已停止"
    else
        log_warning "MySQL 仍在运行"
    fi
    
    echo ""
    
    # 汇总
    print_section "停止完成汇总"
    
    echo "成功停止的 Agent: $success_count/${#NODES[@]}"
    echo ""
    
    if [ $success_count -eq ${#NODES[@]} ]; then
        log_success "集群停止成功！"
    else
        log_warning "部分服务停止失败，可使用 make force-stop 强制停止"
    fi
    
    echo ""
}

# ==========================================
# 重启服务
# ==========================================
restart_cluster() {
    print_header "重启 CDH 集群"
    
    echo ""
    stop_cluster
    
    echo ""
    log_step "等待 5 秒..."
    sleep 5
    
    echo ""
    start_cluster
}

# ==========================================
# 查看状态
# ==========================================
status_cluster() {
    print_header "CDH 集群状态"
    
    echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # Master 节点服务
    print_section "Master 节点 (node01) 服务状态"
    
    local services=("mysqld" "httpd" "cloudera-scm-server" "cloudera-scm-agent")
    for service in "${services[@]}"; do
        local status=$(ssh node01 "systemctl is-active $service 2>/dev/null" || echo "inactive")
        if [ "$status" = "active" ]; then
            log_success "$service: $status"
        else
            log_error "$service: $status"
        fi
    done
    
    echo ""
    
    # 所有节点 Agent
    print_section "所有节点 Agent 状态"
    
    for node in "${NODES[@]}"; do
        local status=$(ssh $node "systemctl is-active cloudera-scm-agent 2>/dev/null" || echo "inactive")
        if [ "$status" = "active" ]; then
            log_success "$node: $status"
        else
            log_error "$node: $status"
        fi
    done
    
    echo ""
    
    # 端口检查
    print_section "端口检查"
    
    if ssh node01 "netstat -tlnp | grep 7180" >/dev/null 2>&1; then
        log_success "CM Server Web (7180): 监听中"
    else
        log_error "CM Server Web (7180): 未监听"
    fi
    
    if ssh node01 "netstat -tlnp | grep 7182" >/dev/null 2>&1; then
        log_success "CM Server Admin (7182): 监听中"
    else
        log_warning "CM Server Admin (7182): 未监听"
    fi
    
    if ssh node01 "netstat -tlnp | grep 3306" >/dev/null 2>&1; then
        log_success "MySQL (3306): 监听中"
    else
        log_error "MySQL (3306): 未监听"
    fi
    
    echo ""
}

# ==========================================
# 主函数
# ==========================================
main() {
    case "$1" in
        start)
            start_cluster
            ;;
        stop)
            stop_cluster
            ;;
        restart)
            restart_cluster
            ;;
        status)
            status_cluster
            ;;
        *)
            echo "用法: $0 {start|stop|restart|status}"
            exit 1
            ;;
    esac
}

main "$@"
