#!/bin/bash
# 添加集群节点脚本
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
}

print_header "添加集群节点"

echo "此脚本将帮助您添加 node02 和 node03 到 CDH 集群"
echo ""

# 定义变量
NODES_TO_ADD=("node02" "node03")
CM_SERVER="node01"

# ==========================================
# 检查前置条件
# ==========================================
check_prerequisites() {
    print_section_header "1. 检查前置条件"
    echo ""
    
    local error=0
    
    # 检查 SSH
    for node in "${NODES_TO_ADD[@]}"; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no $node "echo ok" >/dev/null 2>&1; then
            echo -e "${GREEN}[✓]${NC} $node SSH 连接正常"
        else
            echo -e "${RED}[✗]${NC} $node SSH 连接失败"
            error=1
        fi
    done
    
    echo ""
    
    if [ $error -eq 1 ]; then
        echo -e "${RED}错误：${NC}SSH 连接失败，请先配置免密登录"
        echo "运行命令：make setup-ssh"
        return 1
    fi
    
    return 0
}

# ==========================================
# 安装 CM Agent
# ==========================================
install_cm_agent() {
    local node=$1
    print_section_header "安装 CM Agent 到 $node"
    echo ""
    
    log_step "检查 $node 上是否已安装 Agent..."
    
    if ssh $node "rpm -qa | grep cloudera-manager-agent" >/dev/null 2>&1; then
        log_warning "$node 上已安装 Agent"
        return 0
    fi
    
    log_step "在 $node 上安装 CM Agent..."
    
    # 配置 YUM 仓库
    ssh $node "cat > /etc/yum.repos.d/cloudera-manager.repo <<EOF
[cloudera-manager]
name=Cloudera Manager
baseurl=http://$CM_SERVER/cloudera-repos/cm6/6.3.1/redhat7/yum/
gpgcheck=0
enabled=1
EOF"
    
    # 安装 Agent
    ssh $node "yum install -y cloudera-manager-agent cloudera-manager-daemons"
    
    if [ $? -eq 0 ]; then
        log_success "$node Agent 安装成功"
    else
        log_error "$node Agent 安装失败"
        return 1
    fi
    
    return 0
}

# ==========================================
# 配置 CM Agent
# ==========================================
configure_cm_agent() {
    local node=$1
    print_section_header "配置 CM Agent 到 $node"
    echo ""
    
    log_step "配置 $node 的 Agent..."
    
    # 完全重写配置文件，确保正确
    ssh $node "cat > /etc/cloudera-scm-agent/config.ini <<'EOFCONFIG'
[General]
# Hostname of the CM server.
server_host=$CM_SERVER

# Port that the CM server is listening on.
server_port=7182

# The hostname of the agent.
listening_hostname=$node

# The port that the agent should listen on.
listening_port=9000

# The log file for the agent.
log_file=/var/log/cloudera-scm-agent/cloudera-scm-agent.log

# The directory for the agent libraries.
lib_dir=/var/lib/cloudera-scm-agent
EOFCONFIG"
    
    # 验证配置
    local server_host_check=$(ssh $node "grep '^server_host=' /etc/cloudera-scm-agent/config.ini | cut -d= -f2")
    if [ "$server_host_check" == "$CM_SERVER" ]; then
        log_success "$node Agent 配置完成（server_host=$server_host_check）"
    else
        log_error "$node Agent 配置失败（server_host=$server_host_check，期望=$CM_SERVER）"
        return 1
    fi
    
    return 0
}

# ==========================================
# 启动 CM Agent
# ==========================================
start_cm_agent() {
    local node=$1
    print_section_header "启动 CM Agent 在 $node"
    echo ""
    
    log_step "启动 $node 的 Agent..."
    
    ssh $node "systemctl start cloudera-scm-agent"
    ssh $node "systemctl enable cloudera-scm-agent"
    
    if ssh $node "systemctl is-active cloudera-scm-agent" >/dev/null 2>&1; then
        log_success "$node Agent 已启动"
    else
        log_error "$node Agent 启动失败"
        return 1
    fi
    
    return 0
}

# ==========================================
# 安装 Java
# ==========================================
install_java() {
    local node=$1
    print_section_header "安装 Java 到 $node"
    echo ""
    
    log_step "检查 $node 上是否已安装 Java..."
    
    if ssh $node "java -version" >/dev/null 2>&1; then
        log_warning "$node 上已安装 Java"
        return 0
    fi
    
    log_step "从 node01 复制 Java 到 $node..."
    
    # 复制 Java
    ssh $node "mkdir -p /usr/java"
    scp -r /usr/java/jdk* $node:/usr/java/
    ssh $node "ln -sf /usr/java/jdk* /usr/java/default"
    
    # 配置环境变量
    ssh $node "cat >> /etc/profile <<EOF
# Java Environment
export JAVA_HOME=/usr/java/default
export JRE_HOME=\\\$JAVA_HOME/jre
export PATH=\\\$PATH:\\\$JAVA_HOME/bin
export CLASSPATH=.:\\\$JAVA_HOME/lib/dt.jar:\\\$JAVA_HOME/lib/tools.jar
EOF"
    
    log_success "$node Java 安装完成"
    
    return 0
}

# ==========================================
# 主流程
# ==========================================
main() {
    echo "准备添加节点到 CDH 集群"
    echo "目标节点：${NODES_TO_ADD[@]}"
    echo ""
    
    # 确认
    read -p "$(echo -e ${YELLOW}是否继续？[yes/no]: ${NC})" confirm
    if [ "$confirm" != "yes" ]; then
        log_warning "用户取消操作"
        exit 0
    fi
    
    echo ""
    
    # 检查前置条件
    if ! check_prerequisites; then
        exit 1
    fi
    
    # 处理每个节点
    for node in "${NODES_TO_ADD[@]}"; do
        echo ""
        print_header "处理节点: $node"
        echo ""
        
        # 安装 Java
        if ! install_java $node; then
            log_error "$node Java 安装失败"
            continue
        fi
        
        # 安装 Agent
        if ! install_cm_agent $node; then
            log_error "$node Agent 安装失败"
            continue
        fi
        
        # 配置 Agent
        if ! configure_cm_agent $node; then
            log_error "$node Agent 配置失败"
            continue
        fi
        
        # 启动 Agent
        if ! start_cm_agent $node; then
            log_error "$node Agent 启动失败"
            continue
        fi
        
        log_success "$node 添加成功！"
    done
    
    # 最终提示
    print_header "完成"
    echo ""
    echo "✅ 节点添加完成！"
    echo ""
    echo "📋 后续步骤："
    echo "  1. 等待 1-2 分钟让 Agent 连接到 CM Server"
    echo "  2. 访问 CM 界面：http://node01:7180"
    echo "  3. 在 Hosts > All Hosts 中应该能看到新节点"
    echo "  4. 如果看到新节点，可以将它们添加到集群中"
    echo ""
    echo "🔍 验证命令："
    echo "  # 检查 Agent 状态"
    echo "  ssh node02 'systemctl status cloudera-scm-agent'"
    echo "  ssh node03 'systemctl status cloudera-scm-agent'"
    echo ""
    echo "  # 检查 Agent 日志"
    echo "  ssh node02 'tail -f /var/log/cloudera-scm-agent/cloudera-scm-agent.log'"
    echo ""
}

main
