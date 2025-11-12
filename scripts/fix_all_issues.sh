#!/bin/bash
# 完整项目修复脚本
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# date: 2025-11-12
# 功能：修复所有已知问题

set -e

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
    print_header() { echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "  $1"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo ""; }
    print_section() { echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "  $1"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }
}

print_header "CDH 项目完整修复"

echo "修复时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "本脚本将修复以下问题："
echo "  1. CM Agent 配置错误（server_host=localhost）"
echo "  2. Parcel BitTorrent 分发问题"
echo "  3. SSH known_hosts 警告"
echo "  4. 文件权限问题"
echo "  5. 仓库配置优化"
echo ""

read -p "是否继续修复？[yes/no]: " confirm
if [ "$confirm" != "yes" ]; then
    log_warning "用户取消修复"
    exit 0
fi

NODES=("node01" "node02" "node03")

# ==========================================
# 修复 1: CM Agent 配置
# ==========================================
print_section "修复 1/5: CM Agent 配置"

for node in "${NODES[@]}"; do
    log_step "检查 $node Agent 配置..."
    
    # 检查配置文件是否存在
    if ! ssh $node "test -f /etc/cloudera-scm-agent/config.ini" 2>/dev/null; then
        log_warning "$node: Agent 配置文件不存在，跳过"
        continue
    fi
    
    # 读取当前配置
    local server_host=$(ssh $node "grep '^server_host=' /etc/cloudera-scm-agent/config.ini 2>/dev/null | cut -d= -f2" 2>/dev/null || echo "")
    
    if [ -z "$server_host" ]; then
        log_warning "$node: 无法读取 server_host 配置"
        log_step "重写配置文件..."
        ssh $node "cat > /etc/cloudera-scm-agent/config.ini <<'EOFCONFIG'
[General]
server_host=node01
server_port=7182
EOFCONFIG"
        log_success "$node: 配置已重写"
    elif [ "$server_host" != "node01" ]; then
        log_error "$node: server_host=$server_host (错误)"
        log_step "修复配置..."
        ssh $node "sed -i 's/^server_host=.*/server_host=node01/' /etc/cloudera-scm-agent/config.ini"
        log_success "$node: 配置已修复"
    else
        log_success "$node: server_host=$server_host (正确)"
    fi
done

echo ""

# ==========================================
# 修复 2: 禁用 BitTorrent 分发
# ==========================================
print_section "修复 2/5: 禁用 Parcel BitTorrent 分发"

log_step "检查 CM Server 状态..."
if systemctl is-active cloudera-scm-server >/dev/null 2>&1; then
    log_success "CM Server 运行中"
    
    log_step "禁用 BitTorrent 分发..."
    curl -s -X PUT -u admin:admin \
      -H "Content-Type:application/json" \
      -d '{"items":[{"name":"distribute_parcels_with_torrents","value":"false"}]}' \
      http://localhost:7180/api/v40/cm/config >/dev/null 2>&1 && \
      log_success "BitTorrent 分发已禁用" || \
      log_warning "禁用失败（可能需要手动配置）"
else
    log_warning "CM Server 未运行，跳过此步骤"
fi

echo ""

# ==========================================
# 修复 3: SSH known_hosts
# ==========================================
print_section "修复 3/5: SSH known_hosts 配置"

log_step "配置 SSH 免警告..."

# 检查 SSH config
if [ -f ~/.ssh/config ]; then
    if grep -q "StrictHostKeyChecking no" ~/.ssh/config 2>/dev/null; then
        log_success "SSH config 已配置"
    else
        log_step "添加 SSH config..."
        cat >> ~/.ssh/config <<'EOF'

Host node*
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
EOF
        chmod 600 ~/.ssh/config
        log_success "SSH config 已添加"
    fi
else
    log_step "创建 SSH config..."
    cat > ~/.ssh/config <<'EOF'
Host node*
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
EOF
    chmod 600 ~/.ssh/config
    log_success "SSH config 已创建"
fi

# 预先接受所有节点的 SSH 密钥
log_step "预先接受所有节点 SSH 密钥..."
for node in "${NODES[@]}"; do
    ssh-keyscan -H $node >> ~/.ssh/known_hosts 2>/dev/null
done
log_success "SSH 密钥已接受"

echo ""

# ==========================================
# 修复 4: 文件权限
# ==========================================
print_section "修复 4/5: 文件权限"

log_step "修复项目脚本权限..."
chmod +x $PROJECT_DIR/scripts/*.sh 2>/dev/null
log_success "脚本权限已修复"

log_step "修复仓库文件权限..."
if [ -d /var/www/html/cloudera-repos ]; then
    chmod -R 755 /var/www/html/cloudera-repos
    find /var/www/html/cloudera-repos -type f -exec chmod 644 {} \;
    log_success "仓库文件权限已修复"
else
    log_warning "仓库目录不存在，跳过"
fi

echo ""

# ==========================================
# 修复 5: Parcel 手动分发准备
# ==========================================
print_section "修复 5/5: Parcel 分发准备"

log_step "创建 Parcel 目录..."
for node in "${NODES[@]}"; do
    ssh $node "mkdir -p /opt/cloudera/parcel-cache /opt/cloudera/parcels" 2>/dev/null
done
log_success "Parcel 目录已创建"

log_step "检查 Parcel 文件..."
PARCEL_DIR="/var/www/html/cloudera-repos/cdh6"
if [ -d "$PARCEL_DIR" ]; then
    PARCEL_COUNT=$(find $PARCEL_DIR -name "CDH-*.parcel" -type f 2>/dev/null | wc -l)
    if [ $PARCEL_COUNT -gt 0 ]; then
        log_success "找到 $PARCEL_COUNT 个 Parcel 文件"
        
        log_step "设置 Parcel 文件权限..."
        find $PARCEL_DIR -name "*.parcel*" -type f -exec chmod 644 {} \;
        log_success "Parcel 文件权限已设置"
    else
        log_warning "未找到 Parcel 文件"
    fi
else
    log_warning "Parcel 目录不存在: $PARCEL_DIR"
fi

# 设置所有节点的 cloudera 目录权限
log_step "设置节点 Parcel 目录权限..."
for node in "${NODES[@]}"; do
    ssh $node "chown -R cloudera-scm:cloudera-scm /opt/cloudera 2>/dev/null || true"
done
log_success "节点权限已设置"

echo ""

# ==========================================
# 汇总
# ==========================================
print_section "修复完成汇总"

echo "修复时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "✅ 已完成的修复："
echo "  1. CM Agent 配置（所有节点 server_host=node01）"
echo "  2. 禁用 Parcel BitTorrent 分发"
echo "  3. SSH known_hosts 配置"
echo "  4. 文件权限修复"
echo "  5. Parcel 分发准备"
echo ""
echo "📋 后续步骤："
echo "  1. 重启 Agent 使配置生效:"
echo "     make restart"
echo ""
echo "  2. 在 CM 界面重试添加集群"
echo "     http://node01:7180 或 http://192.168.56.151:7180"
echo ""
echo "  3. 如果 Parcel 分发仍失败，运行手动分发:"
echo "     bash $PROJECT_DIR/scripts/manual_distribute_parcel.sh"
echo ""
echo "🔍 验证命令："
echo "  make check-nodes    # 检查节点状态"
echo "  make status         # 检查服务状态"
echo ""

log_success "项目修复完成！"
