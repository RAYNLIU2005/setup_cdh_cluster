#!/bin/bash
# 检查集群节点状态
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn

# 加载输出格式化库
PROJECT_DIR=/root/setup_cdh_cluster
source "$PROJECT_DIR/lib/output_formatter.sh" 2>/dev/null || {
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
}

print_header "集群节点状态检查"

echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 定义节点
NODES=("node01" "node02" "node03")

# 打印分隔线函数
print_section() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# 检查 hosts 文件配置
check_hosts_config() {
    print_section "1. 检查 /etc/hosts 配置"
    
    for node in "${NODES[@]}"; do
        if grep -q "$node" /etc/hosts; then
            local ip=$(grep "$node" /etc/hosts | awk '{print $1}' | head -1)
            echo -e "${GREEN}[✓]${NC} $node - $ip"
        else
            echo -e "${RED}[✗]${NC} $node - 未配置"
        fi
    done
}

# 检查节点连通性
check_network() {
    print_section "2. 检查节点网络连通性"
    
    for node in "${NODES[@]}"; do
        if ping -c 1 -W 2 $node >/dev/null 2>&1; then
            echo -e "${GREEN}[✓]${NC} $node - 网络连通"
        else
            echo -e "${RED}[✗]${NC} $node - 网络不通"
        fi
    done
}

# 检查 SSH 连接
check_ssh() {
    print_section "3. 检查 SSH 免密登录"
    
    for node in "${NODES[@]}"; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no $node "echo ok" >/dev/null 2>&1; then
            echo -e "${GREEN}[✓]${NC} $node - SSH 正常"
        else
            echo -e "${RED}[✗]${NC} $node - SSH 失败"
        fi
    done
}

# 检查 CM Agent 状态
check_agents() {
    print_section "4. 检查 Cloudera Manager Agent"
    
    local running_count=0
    
    for node in "${NODES[@]}"; do
        if ssh -o ConnectTimeout=5 $node "systemctl is-active cloudera-scm-agent" >/dev/null 2>&1; then
            echo -e "${GREEN}[✓]${NC} $node - Agent 运行中"
            ((running_count++))
        else
            echo -e "${RED}[✗]${NC} $node - Agent 未运行或未安装"
        fi
    done
    
    return $running_count
}

# 检查 CM Server
check_cm_server() {
    print_section "5. 检查 CM Server 识别的主机"
    
    if systemctl is-active cloudera-scm-server >/dev/null 2>&1; then
        echo "CM Server 运行中，检查主机数量..."
        echo ""
        
        # 尝试通过日志检查
        if [ -f "/var/log/cloudera-scm-server/cloudera-scm-server.log" ]; then
            local agent_count=$(grep -i "agent" /var/log/cloudera-scm-server/cloudera-scm-server.log | grep -i "heartbeat" | tail -50 | grep -o "node[0-9]*" | sort -u | wc -l)
            echo "从日志中检测到 $agent_count 个活跃的 Agent 连接"
        fi
        
        echo ""
        echo -e "${YELLOW}💡 提示：${NC}"
        echo "  请在 CM Web 界面检查："
        echo "  http://node01:7180"
        echo "  用户名: admin"
        echo "  密码: admin"
        echo "  导航到: Hosts > All Hosts"
    else
        echo -e "${RED}[✗]${NC} CM Server 未运行"
    fi
}

# 显示结果汇总
show_summary() {
    local agent_count=$1
    
    print_section "检查结果汇总"
    
    if [ $agent_count -eq 3 ]; then
        echo -e "${GREEN}✅ 所有节点 Agent 都在运行！${NC}"
        echo ""
        echo "📋 后续步骤："
        echo "  1. 刷新 CM Web 界面：http://node01:7180"
        echo "  2. 如果界面只显示1个节点，等待1-2分钟后再刷新"
        echo "  3. 或者重启 CM Server："
        echo "     sudo systemctl restart cloudera-scm-server"
        echo ""
        echo "💡 Agent 可能需要几分钟才能在 CM 界面显示"
    elif [ $agent_count -gt 0 ]; then
        echo -e "${YELLOW}⚠ 部分节点 Agent 运行（$agent_count/3）${NC}"
        echo ""
        echo "📋 建议操作："
        echo "  1. 启动未运行的 Agent"
        echo "  2. 运行: make add-nodes"
    else
        echo -e "${RED}✗ 所有 Agent 都未运行${NC}"
        echo ""
        echo "📋 建议操作："
        echo "  1. 运行: make add-nodes"
        echo "  2. 或重新部署: make deploy"
    fi
}

# 执行所有检查
check_hosts_config
check_network  
check_ssh
check_agents
agent_count=$?
check_cm_server
show_summary $agent_count
