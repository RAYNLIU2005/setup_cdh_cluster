#!/bin/bash
# SSH 免密登录配置脚本
# 
# ⚠️ 重要声明：本脚本的核心实现完全来自 playground 项目！
# 灵感来源：https://gitee.com/several-boats/playground.git
# 参考文件：playground/systems/sshFreeLogin.sh
# 
# 使用 expect 工具自动化处理 SSH 密钥复制，实现免密登录
# 该方案经过 playground 项目验证，稳定可靠
#
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# Copyright © 2025 RaynLiu
# Inspired by playground project

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
# 读取环境配置（参考 playground 的配置方式）
# ==========================================
load_env_config() {
    if [ -f "$ENV_FILE" ]; then
        # 读取 SSH 配置
        SSH_USER=$(grep "^SSH_USER=" "$ENV_FILE" | cut -d '=' -f2)
        SSH_PASSWORD=$(grep "^SSH_PASSWORD=" "$ENV_FILE" | cut -d '=' -f2)
        
        # 读取节点配置
        MASTER_NODE=$(grep "^MASTER_NODE=" "$ENV_FILE" | cut -d '=' -f2)
        SLAVE_NODE_1=$(grep "^SLAVE_NODE_1=" "$ENV_FILE" | cut -d '=' -f2)
        SLAVE_NODE_2=$(grep "^SLAVE_NODE_2=" "$ENV_FILE" | cut -d '=' -f2)
        
        # 设置默认值
        SSH_USER=${SSH_USER:-root}
        SSH_PASSWORD=${SSH_PASSWORD:-123456}
        MASTER_NODE=${MASTER_NODE:-node01}
        SLAVE_NODE_1=${SLAVE_NODE_1:-node02}
        SLAVE_NODE_2=${SLAVE_NODE_2:-node03}
        
        return 0
    else
        # 使用默认配置
        SSH_USER=root
        SSH_PASSWORD=123456
        MASTER_NODE=node01
        SLAVE_NODE_1=node02
        SLAVE_NODE_2=node03
        
        log_warn "未找到 .env 文件，使用默认配置"
        return 1
    fi
}

# ==========================================
# 检查并安装 expect（参考 playground）
# ==========================================
check_and_install_expect() {
    log_step "检查 expect 工具..."
    
    if rpm -qa | grep -q expect; then
        log_info "expect 已安装"
        return 0
    else
        log_warn "expect 未安装，正在安装..."
        if yum install -y expect >/dev/null 2>&1; then
            log_info "expect 安装成功"
            return 0
        else
            log_error "expect 安装失败"
            return 1
        fi
    fi
}

# ==========================================
# 生成 SSH 密钥对
# ==========================================
generate_ssh_key() {
    log_step "检查 SSH 密钥..."
    
    if [ ! -f ~/.ssh/id_rsa ]; then
        log_warn "未找到 SSH 密钥，正在生成..."
        ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa >/dev/null 2>&1
        log_info "SSH 密钥生成完成"
    else
        log_info "SSH 密钥已存在"
    fi
}

# ==========================================
# 使用 expect 配置免密登录（参考 playground）
# ==========================================
setup_ssh_with_expect() {
    local hostname=$1
    local username=$2
    local password=$3
    
    # 清除旧的 known_hosts 记录
    ssh-keygen -f ~/.ssh/known_hosts -R "$hostname" >/dev/null 2>&1
    
    # 使用 expect 自动化处理
    expect << EOF >/dev/null 2>&1
set timeout 10
spawn ssh-copy-id -o StrictHostKeyChecking=no ${username}@${hostname}
expect {
    "yes/no" { send "yes\\n"; exp_continue }
    "password:" { send "${password}\\n"; exp_continue }
    eof
}
EOF
    
    return $?
}

# ==========================================
# 使用 sshpass 配置免密登录（备选方案）
# ==========================================
setup_ssh_with_sshpass() {
    local hostname=$1
    local username=$2
    local password=$3
    
    # 清除旧的 known_hosts 记录
    ssh-keygen -f ~/.ssh/known_hosts -R "$hostname" >/dev/null 2>&1
    
    # 使用 sshpass
    sshpass -p "$password" ssh-copy-id -o StrictHostKeyChecking=no ${username}@${hostname} >/dev/null 2>&1
    
    return $?
}

# ==========================================
# 验证 SSH 免密登录
# ==========================================
verify_ssh_connection() {
    local hostname=$1
    local username=$2
    
    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ${username}@${hostname} "exit" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# ==========================================
# 主函数：配置免密登录
# ==========================================
main() {
    log_section "SSH 免密登录配置"
    
    # 1. 加载配置文件
    load_env_config
    has_env_config=$?
    
    echo ""
    
    # 2. 生成 SSH 密钥
    generate_ssh_key
    
    echo ""
    
    # 3. 检查并安装 expect
    use_expect=false
    if check_and_install_expect; then
        use_expect=true
    else
        # 检查 sshpass
        if ! command -v sshpass >/dev/null 2>&1; then
            log_warn "sshpass 未安装，正在安装..."
            yum install -y sshpass >/dev/null 2>&1
        fi
    fi
    
    echo ""
    
    # 4. 确认是否使用默认配置
    if [ $has_env_config -eq 0 ]; then
        log_info "检测到配置文件 .env"
        echo ""
        echo "  SSH 用户: $SSH_USER"
        echo "  节点列表: $MASTER_NODE, $SLAVE_NODE_1, $SLAVE_NODE_2"
        echo ""
        
        read -p "是否使用配置文件中的默认密码? (y/n，默认 y): " use_default
        use_default=${use_default:-y}
        
        if [ "$use_default" = "y" ] || [ "$use_default" = "Y" ]; then
            password="$SSH_PASSWORD"
            log_info "使用默认密码配置"
        else
            log_step "请输入节点密码（所有节点使用相同密码）："
            read -s password
            echo ""
        fi
    else
        log_step "请输入节点密码（所有节点使用相同密码，默认: 123456）："
        read -s password
        echo ""
        password=${password:-123456}
    fi
    
    if [ -z "$password" ]; then
        log_error "密码不能为空"
        exit 1
    fi
    
    # 5. 配置免密登录
    log_section "配置节点免密登录"
    
    # 使用配置文件中的节点或默认节点
    nodes=("$MASTER_NODE" "$SLAVE_NODE_1" "$SLAVE_NODE_2")
    username="${SSH_USER:-root}"
    success_count=0
    failed_nodes=()
    
    for node in "${nodes[@]}"; do
        log_step "配置 $node..."
        
        # 选择使用 expect 或 sshpass
        if [ "$use_expect" = true ]; then
            if setup_ssh_with_expect "$node" "$username" "$password"; then
                log_info "$node 配置成功"
                ((success_count++))
            else
                log_error "$node 配置失败"
                failed_nodes+=("$node")
            fi
        else
            if setup_ssh_with_sshpass "$node" "$username" "$password"; then
                log_info "$node 配置成功"
                ((success_count++))
            else
                log_error "$node 配置失败"
                failed_nodes+=("$node")
            fi
        fi
    done
    
    echo ""
    
    # 5. 验证连接
    log_section "验证 SSH 连接"
    
    verified_count=0
    for node in "${nodes[@]}"; do
        if verify_ssh_connection "$node" "$username"; then
            log_info "$node - SSH 免密登录正常"
            ((verified_count++))
        else
            log_warn "$node - SSH 免密登录验证失败"
        fi
    done
    
    echo ""
    
    # 6. 显示结果
    log_section "配置结果"
    
    echo "节点总数: ${#nodes[@]}"
    echo "配置成功: $success_count"
    echo "验证通过: $verified_count"
    
    if [ ${#failed_nodes[@]} -gt 0 ]; then
        echo ""
        log_warn "以下节点配置失败："
        for node in "${failed_nodes[@]}"; do
            echo "  - $node"
        done
        echo ""
        log_warn "💡 手动配置方法："
        log_warn "   ssh-copy-id root@<节点名>"
    fi
    
    echo ""
    
    if [ $verified_count -eq ${#nodes[@]} ]; then
        log_section "✓ SSH 免密登录配置完成"
        exit 0
    else
        log_section "⚠ SSH 免密登录部分节点配置失败"
        exit 1
    fi
}

# 执行主函数
main
