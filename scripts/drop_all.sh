#!/bin/bash
# ==========================================
# CDH 集群完全清理脚本
# Copyright © 2025 RaynLiu
# 保留所有权利 All Rights Reserved
# ==========================================
# 
# 功能：完全停止并清理 CDH 集群环境
# 警告：此操作将删除所有数据和配置，无法恢复！
# 
# 用法：
#   ./drop_all.sh           # 交互式执行（需要确认）
#   ./drop_all.sh --force   # 强制执行（跳过确认）
#   ./drop_all.sh --backup  # 先备份再清理
# ==========================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
PROJECT_DIR="/root/setup_cdh_cluster"
INVENTORY="${PROJECT_DIR}/ansible/node_group/hosts"
BACKUP_DIR="/backup/cdh_backup_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/tmp/cdh_drop.log"  # 改为 /tmp 目录，避免磁盘满

# 日志函数（容错处理）
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> ${LOG_FILE} 2>/dev/null || true
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >> ${LOG_FILE} 2>/dev/null || true
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> ${LOG_FILE} 2>/dev/null || true
}

log_step() {
    echo ""
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}===================================================${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [STEP] $1" >> ${LOG_FILE} 2>/dev/null || true
}

# 显示版权信息
show_banner() {
    echo ""
    echo "=========================================="
    echo "  CDH 集群完全清理工具"
    echo "  Copyright © 2025 RaynLiu"
    echo "  保留所有权利 All Rights Reserved"
    echo "=========================================="
    echo ""
}

# 显示警告信息
show_warning() {
    echo -e "${RED}================================================${NC}"
    echo -e "${RED}              ⚠️  警告 WARNING  ⚠️              ${NC}"
    echo -e "${RED}================================================${NC}"
    echo ""
    echo -e "${YELLOW}此操作将执行以下清理：${NC}"
    echo "  💥 停止所有 CDH 服务"
    echo "  💥 删除所有 MySQL 数据库数据"
    echo "  💥 清理 Cloudera Manager 配置"
    echo "  💥 删除所有日志文件"
    echo "  💥 清理临时文件和缓存"
    echo ""
    echo -e "${RED}⚠️  所有数据将被永久删除，无法恢复！${NC}"
    echo ""
}

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 root 用户运行此脚本"
        exit 1
    fi
}

# 检查磁盘空间并清理
check_disk_space() {
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -gt 95 ]; then
        log_warn "磁盘使用率过高: ${disk_usage}%，开始紧急清理..."
        
        # 紧急清理
        rm -rf /tmp/* 2>/dev/null || true
        rm -rf /var/tmp/* 2>/dev/null || true
        yum clean all 2>/dev/null || true
        rm -rf /var/cache/yum/* 2>/dev/null || true
        find /var/log -type f -name "*.log" -size +100M -delete 2>/dev/null || true
        journalctl --vacuum-size=100M 2>/dev/null || true
        
        disk_usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
        log_info "清理后磁盘使用率: ${disk_usage}%"
    fi
}

# 备份数据
backup_data() {
    log_step "步骤 1: 备份数据"
    
    mkdir -p ${BACKUP_DIR}
    log_info "创建备份目录: ${BACKUP_DIR}"
    
    # 备份 MySQL 数据库
    log_info "备份 MySQL 数据库..."
    if systemctl is-active --quiet mysqld; then
        mysqldump -u root -p'Cloudera!20200801' --all-databases > ${BACKUP_DIR}/all_databases.sql 2>/dev/null || {
            log_warn "MySQL 备份失败，可能是密码错误或服务未运行"
        }
        if [ -f ${BACKUP_DIR}/all_databases.sql ]; then
            log_info "MySQL 备份完成: $(du -h ${BACKUP_DIR}/all_databases.sql | cut -f1)"
        fi
    else
        log_warn "MySQL 服务未运行，跳过数据库备份"
    fi
    
    # 备份配置文件
    log_info "备份配置文件..."
    [ -f /etc/my.cnf ] && cp /etc/my.cnf ${BACKUP_DIR}/ 2>/dev/null
    [ -d /opt/cloudera ] && tar -czf ${BACKUP_DIR}/cloudera_configs.tar.gz /opt/cloudera 2>/dev/null
    
    # 备份部署日志
    [ -f /var/log/cdh_deploy.log ] && cp /var/log/cdh_deploy.log ${BACKUP_DIR}/ 2>/dev/null
    
    log_info "备份完成！备份位置: ${BACKUP_DIR}"
    ls -lh ${BACKUP_DIR}
}

# 停止所有服务
stop_services() {
    log_step "步骤 2: 停止所有服务"
    
    # 停止所有节点的 CM Agent
    log_info "停止所有节点 CM Agent..."
    if [ -f ${INVENTORY} ]; then
        ansible all_node -i ${INVENTORY} -m service -a "name=cloudera-scm-agent state=stopped" 2>/dev/null || {
            log_warn "Ansible 停止 Agent 失败，尝试手动停止"
            for node in node01 node02 node03; do
                ssh $node "systemctl stop cloudera-scm-agent" 2>/dev/null && \
                    log_info "  ✓ $node Agent 已停止" || \
                    log_warn "  ✗ $node Agent 停止失败"
            done
        }
    else
        log_warn "Ansible inventory 不存在，手动停止服务"
        for node in node01 node02 node03; do
            ssh $node "systemctl stop cloudera-scm-agent" 2>/dev/null && \
                log_info "  ✓ $node Agent 已停止" || \
                log_warn "  ✗ $node Agent 停止失败"
        done
    fi
    
    # 停止 Master 节点服务
    log_info "停止 Master 节点服务..."
    
    systemctl stop cloudera-scm-server 2>/dev/null && \
        log_info "  ✓ CM Server 已停止" || \
        log_warn "  ✗ CM Server 停止失败或未运行"
    
    systemctl stop httpd 2>/dev/null && \
        log_info "  ✓ httpd 已停止" || \
        log_warn "  ✗ httpd 停止失败或未运行"
    
    systemctl stop mysqld 2>/dev/null && \
        log_info "  ✓ MySQL 已停止" || \
        log_warn "  ✗ MySQL 停止失败或未运行"
    
    # 等待服务完全停止
    sleep 3
    
    # 强制杀死残留进程
    log_info "检查并清理残留进程..."
    pkill -9 -f cloudera-scm 2>/dev/null || true
    pkill -9 -f mysqld 2>/dev/null || true
    pkill -9 -f httpd 2>/dev/null || true
    
    log_info "所有服务已停止"
}

# 清理 MySQL 数据
clean_mysql() {
    log_step "步骤 3: 清理 MySQL 数据"
    
    log_info "清理 MySQL 数据目录..."
    rm -rf /var/lib/mysql/* 2>/dev/null
    log_info "  ✓ /var/lib/mysql 已清空"
    
    log_info "清理 MySQL 日志..."
    rm -f /var/log/mysqld.log 2>/dev/null
    log_info "  ✓ MySQL 日志已删除"
    
    log_info "MySQL 数据清理完成"
}

# 清理 Cloudera 目录
clean_cloudera() {
    log_step "步骤 4: 清理 Cloudera 目录"
    
    log_info "清理 Cloudera Manager 数据..."
    
    # 清理 parcel-repo（可能是软链接或目录）
    if [ -L /opt/cloudera/parcel-repo ]; then
        log_info "  删除 parcel-repo 软链接"
        rm -f /opt/cloudera/parcel-repo
    elif [ -d /opt/cloudera/parcel-repo ]; then
        log_info "  删除 parcel-repo 目录"
        rm -rf /opt/cloudera/parcel-repo
    fi
    
    # 清理备份目录
    rm -rf /opt/cloudera/parcel-repo.bak 2>/dev/null
    
    # 清理其他 Cloudera 目录
    rm -rf /opt/cloudera/parcels 2>/dev/null
    rm -rf /opt/cloudera/parcel-cache 2>/dev/null
    rm -rf /opt/cloudera/csd 2>/dev/null
    rm -rf /var/lib/cloudera-scm-* 2>/dev/null
    
    log_info "  ✓ Cloudera 目录已清理"
    
    # 清理日志
    log_info "清理 Cloudera 日志..."
    rm -rf /var/log/cloudera-scm-server 2>/dev/null
    rm -rf /var/log/cloudera-scm-agent 2>/dev/null
    log_info "  ✓ Cloudera 日志已清理"
    
    log_info "Cloudera 目录清理完成"
}

# 清理所有节点的临时文件
clean_all_nodes() {
    log_step "步骤 5: 清理所有节点临时文件"
    
    log_info "清理 /opt/setup_cdh 目录..."
    if [ -f ${INVENTORY} ]; then
        ansible all_node -i ${INVENTORY} -m shell -a "
            cd /opt/setup_cdh 2>/dev/null || exit 0
            for file in *; do
                if [ -e \"\$file\" ] && [ ! -L \"\$file\" ]; then
                    rm -f \"\$file\"
                fi
            done
            echo 'setup_cdh 清理完成'
        " 2>/dev/null || log_warn "Ansible 清理失败"
    else
        for node in node01 node02 node03; do
            ssh $node "rm -rf /opt/setup_cdh/*" 2>/dev/null && \
                log_info "  ✓ $node 清理完成" || \
                log_warn "  ✗ $node 清理失败"
        done
    fi
    
    # 清理本地 setup_cdh
    log_info "清理本地 /opt/setup_cdh..."
    cd /opt/setup_cdh 2>/dev/null || true
    for file in *; do
        if [ -e "$file" ] && [ ! -L "$file" ]; then
            rm -f "$file"
        fi
    done
    log_info "  ✓ 本地 setup_cdh 已清理"
    
    log_info "所有节点临时文件清理完成"
}

# 清理日志文件
clean_logs() {
    log_step "步骤 6: 清理日志文件"
    
    log_info "清理部署日志..."
    rm -f /var/log/cdh_deploy.log 2>/dev/null
    rm -f /var/log/httpd/* 2>/dev/null
    
    log_info "  ✓ 日志文件已清理"
}

# 清理 YUM 缓存
clean_yum_cache() {
    log_step "步骤 7: 清理 YUM 缓存"
    
    log_info "清理 YUM 缓存..."
    yum clean all 2>/dev/null
    log_info "  ✓ YUM 缓存已清理"
}

# 显示清理结果
show_result() {
    log_step "清理完成"
    
    echo ""
    log_info "=========================================="
    log_info "  清理结果统计"
    log_info "=========================================="
    
    # 检查服务状态
    echo ""
    log_info "服务状态检查："
    
    systemctl is-active --quiet mysqld && \
        echo -e "  ${RED}✗ MySQL 仍在运行${NC}" || \
        echo -e "  ${GREEN}✓ MySQL 已停止${NC}"
    
    systemctl is-active --quiet cloudera-scm-server && \
        echo -e "  ${RED}✗ CM Server 仍在运行${NC}" || \
        echo -e "  ${GREEN}✓ CM Server 已停止${NC}"
    
    systemctl is-active --quiet httpd && \
        echo -e "  ${RED}✗ httpd 仍在运行${NC}" || \
        echo -e "  ${GREEN}✓ httpd 已停止${NC}"
    
    # 显示磁盘空间
    echo ""
    log_info "当前磁盘使用情况："
    df -h / | tail -1
    
    # 显示备份位置
    if [ -d ${BACKUP_DIR} ]; then
        echo ""
        log_info "备份位置: ${BACKUP_DIR}"
        log_info "备份文件:"
        ls -lh ${BACKUP_DIR}
    fi
    
    echo ""
    log_info "=========================================="
    log_info "  环境已完全清理，可以重新部署"
    log_info "=========================================="
    echo ""
    echo -e "${GREEN}重新部署命令：${NC}"
    echo "  cd /root/setup_cdh_cluster"
    echo "  make deploy"
    echo ""
}

# 主函数
main() {
    # 检查 root 权限
    check_root
    
    # 显示版权信息
    show_banner
    
    # 解析参数
    FORCE_MODE=false
    BACKUP_MODE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force|-f)
                FORCE_MODE=true
                shift
                ;;
            --backup|-b)
                BACKUP_MODE=true
                shift
                ;;
            --help|-h)
                echo "用法: $0 [选项]"
                echo ""
                echo "选项:"
                echo "  --force, -f      强制执行，跳过确认"
                echo "  --backup, -b     先备份再清理"
                echo "  --help, -h       显示此帮助信息"
                echo ""
                echo "示例:"
                echo "  $0              # 交互式执行"
                echo "  $0 --backup     # 先备份再清理"
                echo "  $0 --force      # 强制清理（危险）"
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                exit 1
                ;;
        esac
    done
    
    # 显示警告
    show_warning
    
    # 确认操作
    if [ "$FORCE_MODE" = false ]; then
        read -p "确认要清理所有 CDH 数据吗？此操作无法恢复！输入 'YES' 继续: " confirm
        if [ "$confirm" != "YES" ]; then
            log_warn "操作已取消"
            exit 0
        fi
    else
        log_warn "强制模式：跳过确认"
    fi
    
    # 检查并清理磁盘空间
    check_disk_space
    
    # 开始清理
    log_info "开始清理 CDH 环境..."
    log_info "日志文件: ${LOG_FILE}"
    echo ""
    
    # 备份（如果需要）
    if [ "$BACKUP_MODE" = true ] || [ "$FORCE_MODE" = false ]; then
        backup_data
    fi
    
    # 执行清理步骤
    stop_services
    clean_mysql
    clean_cloudera
    clean_all_nodes
    clean_logs
    clean_yum_cache
    
    # 显示结果
    show_result
    
    log_info "清理完成！"
}

# 执行主函数
main "$@"
