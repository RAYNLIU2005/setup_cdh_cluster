#!/bin/bash
# 同步项目到其他节点
# 参考 playground 的 update_all 功能
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# Copyright © 2025 RaynLiu

# ==========================================
# 颜色定义
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ==========================================
# 项目配置
# ==========================================
PROJECT_DIR=/root/setup_cdh_cluster
ENV_FILE="$PROJECT_DIR/.env"

# ==========================================
# 日志函数
# ==========================================
log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[→]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# ==========================================
# 读取配置
# ==========================================
load_config() {
    if [ -f "$ENV_FILE" ]; then
        MASTER_NODE=$(grep "^MASTER_NODE=" "$ENV_FILE" | cut -d '=' -f2)
        SLAVE_NODE_1=$(grep "^SLAVE_NODE_1=" "$ENV_FILE" | cut -d '=' -f2)
        SLAVE_NODE_2=$(grep "^SLAVE_NODE_2=" "$ENV_FILE" | cut -d '=' -f2)
        
        # 设置默认值
        MASTER_NODE=${MASTER_NODE:-node01}
        SLAVE_NODE_1=${SLAVE_NODE_1:-node02}
        SLAVE_NODE_2=${SLAVE_NODE_2:-node03}
    else
        MASTER_NODE=node01
        SLAVE_NODE_1=node02
        SLAVE_NODE_2=node03
    fi
}

# ==========================================
# 同步到单个节点
# ==========================================
sync_to_node() {
    local node=$1
    local current_host=$(hostname)
    
    # 跳过本机
    if [ "$node" = "$current_host" ]; then
        log_info "$node 是当前主机，跳过同步"
        return 0
    fi
    
    log_step "正在同步到 $node..."
    
    # 检查 SSH 连接
    if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$node" "exit" 2>/dev/null; then
        log_error "$node SSH 连接失败，跳过"
        return 1
    fi
    
    # 在远程主机创建目录
    ssh "$node" "mkdir -p $PROJECT_DIR" 2>/dev/null
    
    # 同步项目文件（排除日志和临时文件）
    # 使用 rsync 显示详细进度（类似 playground）
    if rsync -avz --delete \
        --progress \
        --exclude='.git' \
        --exclude='*.log' \
        --exclude='logs/' \
        --exclude='*.tmp' \
        --exclude='.env' \
        --exclude='SUCCESS' \
        "$PROJECT_DIR/" "$node:$PROJECT_DIR/" 2>&1 | grep -E "\.sh$|\.py$|\.yml$|\.yaml$|\.txt$|\.md$" | head -20; then
        
        log_info "$node 同步成功"
        
        # 赋予脚本执行权限
        ssh "$node" "chmod -R +x $PROJECT_DIR/scripts/*.sh" 2>/dev/null
        
        return 0
    else
        log_error "$node 同步失败"
        return 1
    fi
}

# ==========================================
# 在远程节点执行命令
# ==========================================
execute_on_node() {
    local node=$1
    local current_host=$(hostname)
    
    # 跳过本机
    if [ "$node" = "$current_host" ]; then
        return 0
    fi
    
    log_step "在 $node 上执行环境配置..."
    
    # 执行远程命令（显示详细输出，类似 playground）
    ssh "$node" bash << 'REMOTE_SCRIPT'
    
    echo "DNS配置"
    # 检查 DNS
    if ! grep -q "8.8.8.8" /etc/resolv.conf 2>/dev/null; then
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf 2>/dev/null || true
        echo "nameserver已添加"
    else
        echo "nameserver已存在，跳过添加步骤！"
    fi
    
    echo "配置阿里云镜像源"
    # 清理和重建 YUM 缓存
    yum clean all 2>/dev/null || true
    yum makecache 2>/dev/null || true
    
    # 检查并安装 expect
    if ! command -v expect >/dev/null 2>&1; then
        echo "expect 未安装"
        echo "尝试使用 yum 安装 expect..."
        yum install -y expect 2>&1 | tail -10
        if [ $? -eq 0 ]; then
            echo "expect 安装成功"
        fi
    else
        echo "expect 已安装"
    fi
    
    # 检查并更新 ntpdate
    if ! command -v ntpdate >/dev/null 2>&1; then
        echo "ntpdate 未安装"
        yum install -y ntpdate 2>&1 | tail -10
    else
        echo "ntpdate 已安装"
        yum update -y ntpdate 2>&1 | tail -10
    fi
    
    # NTP 时间同步
    ntpdate cn.pool.ntp.org 2>&1 || ntpdate pool.ntp.org 2>&1 || true
    
    echo "将集群ip及其映射的hostname添加到/etc/hosts中"
    # hosts 配置在主节点已经处理
    
    echo "关闭防火墙、SELINUX"
    # 关闭防火墙
    systemctl stop firewalld 2>/dev/null || true
    systemctl disable firewalld 2>/dev/null || true
    
    # 关闭 SELinux
    setenforce 0 2>/dev/null || true
    sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config 2>/dev/null || true
    sed -i 's/^SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config 2>/dev/null || true
    
    # 禁用 Swap
    swapoff -a 2>/dev/null || true
    sed -i 's/^\([^#].*swap.*\)$/# \1/' /etc/fstab 2>/dev/null || true
    
    echo "节点环境配置完成"
    
REMOTE_SCRIPT
    
    if [ $? -eq 0 ]; then
        log_info "$node 环境配置完成"
        
        # 显示成功提示框
        echo "┌────────────────────────┐"
        echo "│  环境初始化成功！      │"
        echo "└────────────────────────┘"
        
        return 0
    else
        log_warn "$node 环境配置失败（非致命错误）"
        return 1
    fi
}

# ==========================================
# 主函数
# ==========================================
main() {
    log_section "同步项目到集群节点"
    
    # 加载配置
    load_config
    
    echo -e "${CYAN}目标节点：${NC}"
    echo "  - $MASTER_NODE"
    echo "  - $SLAVE_NODE_1"
    echo "  - $SLAVE_NODE_2"
    echo ""
    
    # 当前主机
    current_host=$(hostname)
    log_info "当前主机: $current_host"
    echo ""
    
    # 同步到所有节点
    success_count=0
    failed_nodes=()
    
    for node in "$MASTER_NODE" "$SLAVE_NODE_1" "$SLAVE_NODE_2"; do
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        log_step "目前正在设置 $node 节点的系统环境"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        if sync_to_node "$node"; then
            # 在远程节点上配置系统环境
            execute_on_node "$node"
            
            ((success_count++))
        else
            failed_nodes+=("$node")
        fi
        
        echo ""
    done
    
    # 显示结果
    log_section "同步结果"
    
    echo "节点总数: 3"
    echo "同步成功: $success_count"
    
    if [ ${#failed_nodes[@]} -gt 0 ]; then
        echo ""
        log_warn "以下节点同步失败："
        for node in "${failed_nodes[@]}"; do
            echo "  - $node"
        done
    fi
    
    echo ""
    
    if [ $success_count -eq 3 ]; then
        log_section "✓ 集群节点同步完成"
        exit 0
    else
        log_section "⚠ 部分节点同步失败"
        exit 1
    fi
}

# 执行主函数
main
