#!/bin/bash
# SSH 免密登录配置脚本
# Copyright © 2025 RaynLiu

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 节点信息
NODE01="192.168.56.151"
NODE02="192.168.56.152"
NODE03="192.168.56.153"
PASSWORD="123456"

echo "=========================================="
echo "  SSH 免密登录配置工具"
echo "  Copyright © 2025 RaynLiu"
echo "=========================================="
echo ""

log_info "节点信息:"
echo "  node01 (Master): $NODE01"
echo "  node02 (Slave):  $NODE02"
echo "  node03 (Slave):  $NODE03"
echo ""

# 安装 sshpass
log_info "检查并安装 sshpass..."
if ! command -v sshpass &> /dev/null; then
    yum install -y sshpass
    log_info "✓ sshpass 已安装"
else
    log_info "✓ sshpass 已存在"
fi

# 生成 SSH 密钥（如果不存在）
log_info "检查 SSH 密钥..."
if [ ! -f ~/.ssh/id_rsa ]; then
    log_info "生成 SSH 密钥..."
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa -q
    log_info "✓ SSH 密钥已生成"
else
    log_info "✓ SSH 密钥已存在"
fi

# 配置 SSH 客户端选项
log_info "配置 SSH 客户端..."
cat > ~/.ssh/config << 'EOF'
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    ConnectTimeout=10
EOF
chmod 600 ~/.ssh/config
log_info "✓ SSH 配置已更新"

echo ""
log_info "=========================================="
log_info "  开始配置免密登录"
log_info "=========================================="
echo ""

# 配置函数
setup_ssh_to_node() {
    local node_name=$1
    local node_ip=$2
    
    log_info "配置 $node_name ($node_ip)..."
    
    # 复制公钥
    sshpass -p "$PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no root@$node_ip 2>/dev/null
    
    # 测试连接
    if ssh -o ConnectTimeout=5 root@$node_ip "hostname" >/dev/null 2>&1; then
        log_info "✓ $node_name 免密登录配置成功"
        return 0
    else
        log_error "✗ $node_name 免密登录配置失败"
        return 1
    fi
}

# 配置到所有节点的免密登录
success_count=0
for node in "node01:$NODE01" "node02:$NODE02" "node03:$NODE03"; do
    node_name=$(echo $node | cut -d: -f1)
    node_ip=$(echo $node | cut -d: -f2)
    
    if setup_ssh_to_node "$node_name" "$node_ip"; then
        ((success_count++))
    fi
done

echo ""
log_info "=========================================="
if [ $success_count -eq 3 ]; then
    log_info "  ✓ 所有节点免密登录配置完成！"
    log_info "=========================================="
    echo ""
    log_info "测试连接:"
    for node in node01 node02 node03; do
        echo -n "  $node: "
        if ssh $node "hostname" 2>/dev/null; then
            echo "    ✓ 可以免密连接"
        fi
    done
    echo ""
    log_info "现在可以使用以下命令："
    echo "  make nodes      # 检查节点连通性"
    echo "  make start-all  # 启动所有节点"
    echo "  make health     # 健康检查"
else
    log_error "  部分节点配置失败！"
    log_info "=========================================="
    exit 1
fi
