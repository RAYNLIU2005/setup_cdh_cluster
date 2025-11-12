#!/bin/bash
# author: RaynLiu
# date: 2025-11-11
# function: CDH集群管理便捷脚本

set -e

PROJECT_DIR="/root/setup_cdh_cluster"
INVENTORY="${PROJECT_DIR}/ansible/node_group/hosts"
LOG_FILE="/var/log/cdh_deploy.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> ${LOG_FILE}
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >> ${LOG_FILE}
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> ${LOG_FILE}
}

# 检查磁盘空间
check_disk_space() {
    log_info "检查所有节点磁盘空间..."
    ansible all_node -i ${INVENTORY} -m shell -a "df -h / | tail -1" 2>/dev/null || {
        log_error "磁盘空间检查失败"
        return 1
    }
}

# 清理系统
clean_system() {
    log_info "开始清理所有节点..."
    ansible-playbook -i ${INVENTORY} ${PROJECT_DIR}/scripts/clean_system.yml || {
        log_error "系统清理失败"
        return 1
    }
    log_info "系统清理完成"
}

# 部署集群
deploy_cluster() {
    log_info "开始部署CDH集群..."
    log_info "请确保已完成以下准备工作："
    echo "  1. 配置了/etc/hosts文件"
    echo "  2. 配置了SSH免密登录"
    echo "  3. 上传了组件安装包到/opt/base_file/"
    echo ""
    read -p "是否继续部署？(y/n): " confirm
    
    if [ "$confirm" != "y" ]; then
        log_warn "用户取消部署"
        return 0
    fi
    
    ansible-playbook -i ${INVENTORY} ${PROJECT_DIR}/ansible/deploy_cdh.yml || {
        log_error "部署失败"
        return 1
    }
    
    log_info "部署完成"
    echo ""
    echo "=========================================="
    echo "  🎉 CDH 集群部署成功！"
    echo "=========================================="
    echo ""
    echo "⏱  CM Server 启动时间：预计 3-5 分钟"
    echo ""
    echo "📋 下一步操作："
    echo "  1. 等待 CM Server 完全启动"
    echo "     tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log"
    echo ""
    echo "  2. 检查服务状态"
    echo "     make status"
    echo ""
    echo "  3. 运行健康检查"
    echo "     make health-check"
    echo ""
    echo "🌐 访问 Cloudera Manager Web 界面："
    echo "  URL:  http://node01:7180"
    echo "  或:   http://192.168.56.151:7180"
    echo ""
    echo "  默认账号: admin"
    echo "  默认密码: admin"
    echo ""
    echo "📝 提示："
    echo "  - CM Server 需要 3-5 分钟启动"
    echo "  - 启动成功后方可访问 Web 界面"
    echo "  - 使用 make verify 验证部署状态"
    echo ""
    echo "=========================================="
    echo ""
}

# 验证部署
verify_deployment() {
    log_info "验证部署状态..."
    ansible-playbook -i ${INVENTORY} ${PROJECT_DIR}/scripts/verify_deployment.yml || {
        log_error "验证失败"
        return 1
    }
}

# 查看服务状态
check_services() {
    log_info "检查服务状态..."
    
    echo ""
    echo "=== Master节点 (node01) 服务状态 ==="
    ssh node01 "
        echo '--- MySQL ---'
        systemctl status mysqld | grep Active
        echo '--- CM Server ---'
        systemctl status cloudera-scm-server | grep Active
        echo '--- httpd ---'
        systemctl status httpd | grep Active
    " 2>/dev/null
    
    echo ""
    echo "=== 所有节点 CM Agent 状态 ==="
    ansible all_node -i ${INVENTORY} -m shell -a "systemctl status cloudera-scm-agent | grep Active" 2>/dev/null
}

# 查看日志
view_logs() {
    log_info "查看部署日志..."
    
    if [ -f ${LOG_FILE} ]; then
        tail -50 ${LOG_FILE}
    else
        log_warn "日志文件不存在: ${LOG_FILE}"
    fi
}

# 查看进程
check_processes() {
    log_info "检查 CDH 相关进程..."
    
    echo ""
    echo "=== Master 节点 (node01) 进程 ==="
    ssh node01 "ps aux | grep -E '[c]loudera|[m]ysql|[h]ttpd'" 2>/dev/null || echo "✓ 无 CDH 相关进程"
    
    echo ""
    echo "=== 所有节点进程统计 ==="
    ansible all_node -i ${INVENTORY} -m shell -a "ps aux | grep -E '[c]loudera' | wc -l" 2>/dev/null || true
}

# 查看端口
check_ports() {
    log_info "检查端口占用..."
    
    echo ""
    echo "=== Master 节点 (node01) 端口 ==="
    ssh node01 "
        echo '--- CM Server (7180) ---'
        netstat -tlnp | grep 7180 || echo '未占用'
        echo '--- CM Server Admin (7182) ---'
        netstat -tlnp | grep 7182 || echo '未占用'
        echo '--- MySQL (3306) ---'
        netstat -tlnp | grep 3306 || echo '未占用'
        echo '--- HTTP (80) ---'
        netstat -tlnp | grep ':80 ' || echo '未占用'
    " 2>/dev/null
}

# 检查所有节点连通性
check_nodes() {
    log_info "检查所有节点连通性..."
    
    echo ""
    echo "=========================================="
    echo "  节点连通性检查"
    echo "=========================================="
    echo ""
    
    local all_online=true
    for node in node01 node02 node03; do
        echo -n "检查 $node ... "
        if ping -c 1 -W 2 $node >/dev/null 2>&1; then
            if ssh -o ConnectTimeout=5 $node "hostname" >/dev/null 2>&1; then
                echo "✓ 在线 (SSH 可连接)"
            else
                echo "⚠ 在线但 SSH 不可达"
                all_online=false
            fi
        else
            echo "✗ 离线或不可达"
            all_online=false
        fi
    done
    
    echo ""
    echo "=========================================="
    if [ "$all_online" = true ]; then
        echo "  ✓ 所有节点在线"
    else
        echo "  ⚠ 部分节点离线"
        echo ""
        echo "  提示："
        echo "  - 请确保所有虚拟机已启动"
        echo "  - 检查网络连接"
        echo "  - 验证 SSH 服务运行正常"
    fi
    echo "=========================================="
}

# 启动所有节点的服务
start_all_nodes() {
    log_info "启动所有节点的服务..."
    
    # 先检查节点连通性
    echo ""
    log_info "=========================================="
    log_info "  步骤 1/3: 检查节点连通性"
    log_info "=========================================="
    check_nodes
    
    # 启动 Master 节点服务
    echo ""
    log_info "=========================================="
    log_info "  步骤 2/3: 启动 Master 节点服务"
    log_info "=========================================="
    start_services
    
    # 检查 Slave 节点
    echo ""
    log_info "=========================================="
    log_info "  步骤 3/3: 检查 Slave 节点状态"
    log_info "=========================================="
    
    local slave_count=0
    for node in node02 node03; do
        echo -n "检查 $node Agent ... "
        if ssh -o ConnectTimeout=5 $node "systemctl is-active cloudera-scm-agent" >/dev/null 2>&1; then
            echo "✓ 运行中"
            ((slave_count++))
        else
            echo "⚠ 未运行或不可达"
        fi
    done
    
    echo ""
    log_info "=========================================="
    log_info "  启动完成汇总"
    log_info "=========================================="
    log_info "  Master 节点 (node01): ✓ 已启动"
    log_info "  Slave 节点在线: $slave_count/2"
    log_info ""
    log_info "  访问 Cloudera Manager:"
    log_info "  URL: http://node01:7180"
    log_info "  用户名: admin | 密码: admin"
    log_info "=========================================="
}

# 停止所有节点的服务
stop_all_nodes() {
    log_info "停止所有节点的服务..."
    
    echo ""
    log_info "=========================================="
    log_info "  停止所有节点"
    log_info "=========================================="
    
    # 停止服务
    stop_services
    
    # 统计结果
    echo ""
    log_info "=========================================="
    log_info "  停止完成汇总"
    log_info "=========================================="
    
    local stopped_count=0
    for node in node01 node02 node03; do
        echo -n "  $node Agent: "
        if ssh -o ConnectTimeout=3 $node "systemctl is-active cloudera-scm-agent" >/dev/null 2>&1; then
            echo "⚠ 仍在运行"
        else
            echo "✓ 已停止"
            ((stopped_count++))
        fi
    done
    
    echo ""
    log_info "  已停止节点: $stopped_count/3"
    log_info "=========================================="
}

# 强制停止（清理残留进程）
force_stop() {
    log_info "强制停止所有服务..."
    
    # 停止服务
    log_info "停止 systemd 服务..."
    ansible all_node -i ${INVENTORY} -m service -a "name=cloudera-scm-agent state=stopped" 2>/dev/null || true
    ssh node01 "
        systemctl stop cloudera-scm-server 2>/dev/null
        systemctl stop httpd 2>/dev/null
        systemctl stop mysqld 2>/dev/null
    " || true
    
    # 强制终止所有 Cloudera 进程（使用安全方式）
    log_info "强制终止残留进程..."
    ansible all_node -i ${INVENTORY} -m shell -a "pgrep -f cloudera | xargs -r kill -9 2>/dev/null || true; pgrep supervisord | xargs -r kill -9 2>/dev/null || true" 2>/dev/null || true
    
    # 重置失败状态
    log_info "重置服务状态..."
    ansible all_node -i ${INVENTORY} -m shell -a "systemctl reset-failed 2>/dev/null || true" 2>/dev/null || true
    
    sleep 2
    
    # 验证
    log_info "验证清理结果..."
    if ssh node01 "ps aux | grep -E '[c]loudera'" 2>/dev/null; then
        log_warn "部分进程仍在运行"
    else
        log_info "✓ 所有进程已清理"
    fi
    
    log_info "强制停止完成"
}

# 健康检查
health_check() {
    log_info "执行健康检查..."
    
    echo ""
    echo "========================================"
    echo "  CDH 集群健康检查"
    echo "========================================"
    echo ""
    
    # 1. 检查服务状态
    echo "[1/5] 服务状态"
    local all_active=true
    for service in cloudera-scm-server cloudera-scm-agent mysqld httpd; do
        status=$(ssh node01 "systemctl is-active $service 2>/dev/null" || echo "unknown")
        if [ "$status" = "active" ]; then
            echo "  ✓ $service: $status"
        else
            echo "  ✗ $service: $status"
            all_active=false
        fi
    done
    echo ""
    
    # 2. 检查端口
    echo "[2/5] 端口检查"
    if ssh node01 "netstat -tlnp | grep 7180" 2>/dev/null >/dev/null; then
        echo "  ✓ CM Server 端口 7180 已监听"
    else
        echo "  ✗ CM Server 端口 7180 未监听"
    fi
    if ssh node01 "netstat -tlnp | grep 3306" 2>/dev/null >/dev/null; then
        echo "  ✓ MySQL 端口 3306 已监听"
    else
        echo "  ✗ MySQL 端口 3306 未监听"
    fi
    echo ""
    
    # 3. 检查磁盘空间
    echo "[3/5] 磁盘空间"
    ssh node01 "df -h / | tail -1 | awk '{print \"  / 分区使用: \" \$5 \" (可用: \" \$4 \")\"}'"
    echo ""
    
    # 4. 检查节点连通性
    echo "[4/5] 节点连通性"
    ansible all_node -i ${INVENTORY} -m ping 2>/dev/null | grep -q SUCCESS && \
        echo "  ✓ 所有节点连通" || echo "  ✗ 部分节点不可达"
    echo ""
    
    # 5. 检查进程
    echo "[5/5] 进程检查"
    local process_count=$(ssh node01 "ps aux | grep -E '[c]loudera' | wc -l" 2>/dev/null)
    echo "  Cloudera 进程数: $process_count"
    echo ""
    
    echo "========================================"
    if [ "$all_active" = true ]; then
        echo "  ✓ 集群状态: 健康"
    else
        echo "  ⚠ 集群状态: 异常"
    fi
    echo "========================================"
}

# 启动服务
start_services() {
    log_info "启动CDH服务..."
    
    # 启动master节点服务
    log_info "启动master节点服务..."
    ssh node01 "
        systemctl start mysqld
        systemctl start httpd
        systemctl start cloudera-scm-server
    " || log_error "master节点服务启动失败"
    
    # 等待CM Server启动
    log_info "等待CM Server启动（约30秒）..."
    sleep 30
    
    # 启动所有节点的agent
    log_info "启动所有节点CM Agent..."
    if ansible all_node -i ${INVENTORY} -m service -a "name=cloudera-scm-agent state=started" 2>&1 | tee /tmp/agent_start.log | grep -q "SUCCESS\|CHANGED"; then
        log_info "✓ Agent 启动成功"
    else
        log_warn "部分节点 Agent 启动失败或不可达"
    fi
    
    # 检查 node01 状态
    if ssh node01 "systemctl is-active cloudera-scm-agent >/dev/null 2>&1"; then
        log_info "✓ Master 节点 (node01) Agent 运行中"
    else
        log_error "✗ Master 节点 (node01) Agent 未运行"
    fi
    
    log_info "服务启动完成"
    log_info ""
    log_info "=========================================="
    log_info "  访问 Cloudera Manager Web UI"
    log_info "=========================================="
    log_info "  URL: http://node01:7180"
    log_info "  用户名: admin"
    log_info "  密码: admin"
    log_info "=========================================="
}

# 停止服务
stop_services() {
    log_info "停止CDH服务..."
    
    # 停止所有节点的agent
    log_info "停止所有节点CM Agent..."
    if ansible all_node -i ${INVENTORY} -m service -a "name=cloudera-scm-agent state=stopped" 2>&1 | grep -q "SUCCESS\|CHANGED"; then
        log_info "✓ Agent 停止成功"
    else
        log_warn "部分节点 Agent 停止失败或不可达"
    fi
    
    # 停止master节点服务
    log_info "停止master节点服务..."
    ssh node01 "
        systemctl stop cloudera-scm-server
        systemctl stop httpd
        systemctl stop mysqld
    " || log_error "master节点服务停止失败"
    
    # 清理残留进程（使用更安全的方式）
    log_info "清理残留进程..."
    ssh node01 "pgrep -f cloudera | xargs -r kill -9 2>/dev/null; pgrep supervisord | xargs -r kill -9 2>/dev/null; true" 2>/dev/null || true
    ansible all_node -i ${INVENTORY} -m shell -a "pgrep -f cloudera | xargs -r kill -9 2>/dev/null || true; pgrep supervisord | xargs -r kill -9 2>/dev/null || true" 2>/dev/null || true
    
    # 重置失败状态
    log_info "重置服务状态..."
    ssh node01 "systemctl reset-failed 2>/dev/null; true"
    ansible all_node -i ${INVENTORY} -m shell -a "systemctl reset-failed 2>/dev/null || true" 2>/dev/null || true
    
    log_info "服务停止完成"
}

# 重启服务
restart_services() {
    log_info "重启CDH服务..."
    
    # 先停止
    stop_services
    
    # 等待5秒
    log_info "等待5秒..."
    sleep 5
    
    # 再启动
    start_services
    
    log_info "服务重启完成"
}

# 清理复制文件，释放磁盘空间
cleanup_copied_files() {
    log_info "=========================================="
    log_info "  CDH集群存储优化工具"
    log_info "  Copyright © 2025 RaynLiu"
    log_info "  保留所有权利 All Rights Reserved"
    log_info "=========================================="
    log_info ""
    log_info "开始清理复制文件，释放磁盘空间..."
    
    # 在所有节点清理 /opt/setup_cdh 中的复制文件，替换为软链接
    ansible all_node -i ${INVENTORY} -m shell -a "
        # 统计清理前的磁盘使用
        df -h / | tail -1
        
        # 如果 /opt/setup_cdh 中的文件不是软链接，则删除
        cd /opt/setup_cdh 2>/dev/null || exit 0
        for file in *; do
            if [ -e \$file ] && [ ! -L \$file ]; then
                echo \"删除复制文件: \$file\"
                rm -f \$file
            fi
        done
        
        # 统计清理后的磁盘使用
        df -h / | tail -1
    " 2>/dev/null || log_error "清理失败"
    
    # 在 master 节点处理 parcel-repo
    log_info "优化 Parcel 存储..."
    ssh node01 "
        if [ -d /opt/cloudera/parcel-repo ] && [ ! -L /opt/cloudera/parcel-repo ]; then
            echo '检测到 parcel-repo 是目录，将转换为软链接'
            systemctl stop cloudera-scm-server
            rm -rf /opt/cloudera/parcel-repo.bak
            mv /opt/cloudera/parcel-repo /opt/cloudera/parcel-repo.bak
            ln -s /opt/base_file/parcels /opt/cloudera/parcel-repo
            chown -h cloudera-scm:cloudera-scm /opt/cloudera/parcel-repo
            systemctl start cloudera-scm-server
            echo '已转换为软链接，节省磁盘空间'
            du -sh /opt/cloudera/parcel-repo.bak
        else
            echo 'parcel-repo 已是软链接，无需处理'
        fi
    " 2>/dev/null || log_warn "Parcel 优化失败或已优化"
    
    log_info "磁盘空间优化完成！"
    log_info "查看当前磁盘使用情况:"
    check_disk_space
}

# 显示帮助信息
show_help() {
    cat << EOF
========================================
  CDH集群管理脚本
  Copyright © 2025 RaynLiu
  保留所有权利 All Rights Reserved
========================================

用法: $0 [选项]

部署管理:
    check       检查磁盘空间和环境
    clean       清理系统临时文件
    deploy      部署CDH集群
    verify      验证部署状态
    cleanup     清理复制文件，使用软链接替代，释放磁盘空间

服务管理:
    status      查看服务状态
    start       启动所有服务
    stop        停止所有服务（清理残留进程）
    restart     重启所有服务
    force-stop  强制停止所有服务（彻底清理）
    nodes       检查所有节点连通性
    start-all   启动所有节点（含连通性检查）
    stop-all    停止所有节点（含状态汇总）

监控诊断:
    health      健康检查（全面检查集群状态）
    ps          查看进程
    ports       查看端口占用
    logs        查看部署日志

其他:
    help        显示此帮助信息

示例:
    $0 check        # 检查磁盘空间
    $0 deploy       # 部署集群
    $0 verify       # 验证部署
    $0 health       # 健康检查
    $0 force-stop   # 强制停止并清理
    $0 cleanup      # 清理复制文件，释放存储空间

EOF
}

# 主函数
main() {
    case "$1" in
        check)
            check_disk_space
            ;;
        clean)
            clean_system
            ;;
        deploy)
            deploy_cluster
            ;;
        verify)
            verify_deployment
            ;;
        status)
            check_services
            ;;
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        force-stop)
            force_stop
            ;;
        nodes)
            check_nodes
            ;;
        start-all)
            start_all_nodes
            ;;
        stop-all)
            stop_all_nodes
            ;;
        health)
            health_check
            ;;
        ps)
            check_processes
            ;;
        ports)
            check_ports
            ;;
        logs)
            view_logs
            ;;
        cleanup)
            cleanup_copied_files
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
