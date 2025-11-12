#!/bin/bash
# 修复 CM Agent 配置脚本
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# date: 2025-11-12
# 说明：修复 Agent 连接到 localhost 的问题

# 加载输出格式化库
PROJECT_DIR=/root/setup_cdh_cluster
source "$PROJECT_DIR/lib/output_formatter.sh" 2>/dev/null || {
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
    log_error() { echo -e "${RED}[✗]${NC} $1"; }
    log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
    log_step() { echo -e "[→] $1"; }
}

print_header "修复 CM Agent 配置"

CM_SERVER="node01"
NODES=("node02" "node03")

for node in "${NODES[@]}"; do
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  处理 $node"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_step "停止 $node 的 Agent..."
    ssh $node "systemctl stop cloudera-scm-agent" 2>/dev/null
    
    log_step "重写 $node 的配置文件..."
    ssh $node "cat > /etc/cloudera-scm-agent/config.ini <<'EOF'
[General]
# Hostname of the CM server.
server_host=node01

# Port that the CM server is listening on.
server_port=7182

# The log file for the agent.
log_file=/var/log/cloudera-scm-agent/cloudera-scm-agent.log

# The directory for the agent libraries.
lib_dir=/var/lib/cloudera-scm-agent
EOF"
    
    log_step "验证配置..."
    local config_check=$(ssh $node "grep '^server_host=' /etc/cloudera-scm-agent/config.ini")
    echo "  $config_check"
    
    log_step "启动 $node 的 Agent..."
    ssh $node "systemctl start cloudera-scm-agent"
    ssh $node "systemctl enable cloudera-scm-agent"
    
    sleep 5
    
    log_step "检查状态..."
    if ssh $node "systemctl is-active cloudera-scm-agent" >/dev/null 2>&1; then
        log_success "$node Agent 已启动"
    else
        log_error "$node Agent 启动失败"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  等待 Agent 连接..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

sleep 30

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  验证连接"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for node in "${NODES[@]}"; do
    echo "=== $node 日志（最后10行）==="
    ssh $node "tail -10 /var/log/cloudera-scm-agent/cloudera-scm-agent.log | grep -E 'node01|heartbeat|INFO|ERROR' || tail -10 /var/log/cloudera-scm-agent/cloudera-scm-agent.log"
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  完成"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ 配置已修复！"
echo ""
echo "📋 后续步骤："
echo "  1. 等待 1-2 分钟"
echo "  2. 刷新 CM 界面：http://node01:7180"
echo "  3. 查看 Hosts > All Hosts"
echo "  4. 应该能看到 3 个节点"
echo ""
