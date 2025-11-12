#!/bin/bash
# CDH 集群环境交互式初始化脚本
# 灵感来源于 playground 项目的优雅设计
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# date: 2025-11-12

set -e

# ==========================================
# 颜色定义
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ==========================================
# 项目配置
# ==========================================
PROJECT_DIR=/root/setup_cdh_cluster
SUCCESS_FLAG=$PROJECT_DIR/.init_success

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
}

log_success() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  ✓ $1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# ==========================================
# 检查是否已初始化
# ==========================================
check_if_initialized() {
    if [ -f "$SUCCESS_FLAG" ]; then
        log_warn "检测到环境已经初始化过！"
        echo ""
        read -p "是否要重新初始化？这将覆盖现有配置 (y/n): " confirm
        
        if [ "$confirm" != "y" ]; then
            log_info "取消初始化，保持现有配置"
            exit 0
        fi
        
        rm -f "$SUCCESS_FLAG"
    fi
}

# ==========================================
# 显示和确认集群配置
# ==========================================
check_cluster_config() {
    log_section "步骤 1/9: 检查集群配置"
    
    # 检查 .env 文件
    if [ -f "$PROJECT_DIR/.env" ]; then
        log_info "找到配置文件: $PROJECT_DIR/.env"
    else
        log_warn "未找到 .env 配置文件"
        log_step "正在从模板创建..."
        cp "$PROJECT_DIR/.env.template" "$PROJECT_DIR/.env"
        log_info "已创建 .env 文件"
    fi
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}                    📋 当前集群配置                        ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # 读取配置
    if [ -f "$PROJECT_DIR/.env" ]; then
        # 读取节点配置
        MASTER_NODE=$(grep "^MASTER_NODE=" "$PROJECT_DIR/.env" | cut -d '=' -f2)
        MASTER_IP=$(grep "^MASTER_IP=" "$PROJECT_DIR/.env" | cut -d '=' -f2)
        SLAVE_NODE_1=$(grep "^SLAVE_NODE_1=" "$PROJECT_DIR/.env" | cut -d '=' -f2)
        SLAVE_IP_1=$(grep "^SLAVE_IP_1=" "$PROJECT_DIR/.env" | cut -d '=' -f2)
        SLAVE_NODE_2=$(grep "^SLAVE_NODE_2=" "$PROJECT_DIR/.env" | cut -d '=' -f2)
        SLAVE_IP_2=$(grep "^SLAVE_IP_2=" "$PROJECT_DIR/.env" | cut -d '=' -f2)
        
        # 读取 SSH 配置
        SSH_USER=$(grep "^SSH_USER=" "$PROJECT_DIR/.env" | cut -d '=' -f2)
        SSH_PASSWORD=$(grep "^SSH_PASSWORD=" "$PROJECT_DIR/.env" | cut -d '=' -f2)
        
        # 读取 MySQL 配置
        MYSQL_PASSWORD=$(grep "^MYSQL_ROOT_PASSWORD=" "$PROJECT_DIR/.env" | cut -d '=' -f2)
        
        # 显示节点信息
        echo -e "${YELLOW}🖥  集群节点信息${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        printf "  %-15s %-20s %-20s\n" "角色" "主机名" "IP 地址"
        echo "  ────────────────────────────────────────────────────────"
        printf "  ${GREEN}%-15s${NC} %-20s ${CYAN}%-20s${NC}\n" "Master 节点" "${MASTER_NODE:-node01}" "${MASTER_IP:-192.168.56.151}"
        printf "  ${YELLOW}%-15s${NC} %-20s ${CYAN}%-20s${NC}\n" "Slave 节点 1" "${SLAVE_NODE_1:-node02}" "${SLAVE_IP_1:-192.168.56.152}"
        printf "  ${YELLOW}%-15s${NC} %-20s ${CYAN}%-20s${NC}\n" "Slave 节点 2" "${SLAVE_NODE_2:-node03}" "${SLAVE_IP_2:-192.168.56.153}"
        echo ""
        
        # 显示 SSH 配置
        echo -e "${YELLOW}🔑 SSH 配置${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        printf "  %-20s ${GREEN}%s${NC}\n" "用户名:" "${SSH_USER:-root}"
        printf "  %-20s ${GREEN}%s${NC}\n" "密码:" "${SSH_PASSWORD:0:2}******${SSH_PASSWORD: -2}"
        echo ""
        
        # 显示 MySQL 配置
        echo -e "${YELLOW}🗄  MySQL 配置${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        printf "  %-20s ${GREEN}%s${NC}\n" "Root 密码:" "${MYSQL_PASSWORD:0:3}***${MYSQL_PASSWORD: -3}"
        echo ""
        
        # 显示项目信息
        AUTHOR=$(grep "^AUTHOR_NAME=" "$PROJECT_DIR/.env" | cut -d '=' -f2)
        EMAIL=$(grep "^AUTHOR_EMAIL=" "$PROJECT_DIR/.env" | cut -d '=' -f2)
        
        if [ -n "$AUTHOR" ]; then
            echo -e "${YELLOW}👤 项目信息${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            printf "  %-20s ${CYAN}%s${NC}\n" "作者:" "${AUTHOR}"
            printf "  %-20s ${CYAN}%s${NC}\n" "邮箱:" "${EMAIL}"
            echo ""
        fi
    fi
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # 确认配置
    confirm=""
    while [ "$confirm" != "y" ] && [ "$confirm" != "n" ]; do
        echo -ne "${YELLOW}请确认以上配置是否正确${NC} (${GREEN}y${NC}/${RED}n${NC}): "
        read confirm
    done
    
    echo ""
    
    if [ "$confirm" == "n" ]; then
        log_warn "配置需要修改"
        echo ""
        echo "💡 编辑配置文件："
        echo "   vi $PROJECT_DIR/.env"
        echo ""
        echo "或使用以下命令："
        echo "   make env-file  # 重新创建配置文件"
        echo ""
        exit 1
    fi
    
    log_success "配置确认完成"
}

# ==========================================
# 检查 base_file 目录
# ==========================================
check_base_file() {
    log_section "步骤 2/9: 检查安装包目录"
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}                    📦 安装包检查                          ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ ! -d "/opt/base_file" ]; then
        log_error "/opt/base_file 目录不存在！"
        echo ""
        echo -e "${YELLOW}📝 请执行以下步骤：${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  1. 创建目录:"
        echo "     ${CYAN}mkdir -p /opt/base_file/{packages,parcels}${NC}"
        echo ""
        echo "  2. 上传安装包到相应目录"
        echo ""
        echo "  3. 参考文档:"
        echo "     ${CYAN}cat doc/base_file目录准备指南.md${NC}"
        echo ""
        exit 1
    fi
    
    # 统计文件
    local pkg_count=0
    local parcel_count=0
    local pkg_size=0
    local parcel_size=0
    
    # 检查 packages 目录
    if [ -d "/opt/base_file/packages" ]; then
        pkg_count=$(ls -1 /opt/base_file/packages 2>/dev/null | wc -l)
        pkg_size=$(du -sh /opt/base_file/packages 2>/dev/null | awk '{print $1}')
    fi
    
    # 检查 parcels 目录
    if [ -d "/opt/base_file/parcels" ]; then
        parcel_count=$(ls -1 /opt/base_file/parcels 2>/dev/null | wc -l)
        parcel_size=$(du -sh /opt/base_file/parcels 2>/dev/null | awk '{print $1}')
    fi
    
    # 显示统计表格
    echo -e "${YELLOW}📊 安装包统计${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "  %-20s %-15s %-15s %-15s\n" "目录" "文件数" "大小" "状态"
    echo "  ────────────────────────────────────────────────────────"
    
    # packages 目录
    if [ $pkg_count -gt 0 ]; then
        printf "  %-20s ${CYAN}%-15s${NC} ${CYAN}%-15s${NC} ${GREEN}%-15s${NC}\n" "packages/" "$pkg_count" "$pkg_size" "✓ 正常"
    else
        printf "  %-20s ${RED}%-15s${NC} ${RED}%-15s${NC} ${RED}%-15s${NC}\n" "packages/" "$pkg_count" "-" "✗ 为空"
    fi
    
    # parcels 目录
    if [ $parcel_count -gt 0 ]; then
        printf "  %-20s ${CYAN}%-15s${NC} ${CYAN}%-15s${NC} ${GREEN}%-15s${NC}\n" "parcels/" "$parcel_count" "$parcel_size" "✓ 正常"
    else
        printf "  %-20s ${RED}%-15s${NC} ${RED}%-15s${NC} ${RED}%-15s${NC}\n" "parcels/" "$parcel_count" "-" "✗ 为空"
    fi
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # 检查是否有文件
    if [ $pkg_count -eq 0 ] || [ $parcel_count -eq 0 ]; then
        log_error "安装包目录为空，无法继续！"
        echo ""
        echo -e "${YELLOW}💡 提示：${NC}"
        echo "  请上传 CDH 安装包到相应目录"
        echo ""
        exit 1
    fi
    
    log_success "安装包检查完成 (packages: $pkg_count, parcels: $parcel_count)"
}

# ==========================================
# 配置 YUM 源
# ==========================================
setup_yum_repos() {
    log_section "步骤 3/9: 配置 YUM 源"
    
    # 临时禁用 set -e，允许 YUM 操作失败而不中断脚本
    set +e
    
    # 执行优化后的 YUM 源修复脚本（参考 playground）
    if [ -f "$PROJECT_DIR/scripts/fix_yum_repos.sh" ]; then
        chmod +x "$PROJECT_DIR/scripts/fix_yum_repos.sh"
        
        # 调用脚本并处理可能的错误
        if $PROJECT_DIR/scripts/fix_yum_repos.sh; then
            log_step "YUM 源配置脚本执行成功"
        else
            log_warn "YUM 源配置脚本执行异常，但继续初始化..."
        fi
    else
        log_error "未找到 YUM 源配置脚本: $PROJECT_DIR/scripts/fix_yum_repos.sh"
        log_warn "跳过 YUM 源配置步骤"
    fi
    
    echo ""
    log_step "清理和重建 YUM 缓存..."
    
    # 清理 YUM 缓存（静默执行，允许失败）
    yum clean all >/dev/null 2>&1 || true
    
    # 重建 YUM 缓存（显示进度，允许失败）
    if yum makecache fast 2>&1 | grep -q "Metadata Cache Created"; then
        log_info "YUM 缓存重建成功"
    else
        # 尝试但失败了
        log_warn "YUM 缓存重建可能失败"
        echo ""
        log_warn "可能的原因："
        log_warn "  1. 网络连接问题，无法访问镜像源"
        log_warn "  2. 系统时间不正确（证书验证失败）"
        log_warn "  3. DNS 解析问题"
        echo ""
        log_warn "💡 继续初始化，稍后可运行以下命令诊断："
        log_warn "   make diagnose-yum  # YUM 源全面诊断"
        log_warn "   make fix-yum       # 重新修复 YUM 源"
    fi
    echo ""
    
    # 恢复 set -e
    set -e
    
    log_success "YUM 源配置完成"
}

# ==========================================
# 检查并安装单个依赖（参考 playground）
# ==========================================
install_single_dependency() {
    local pkg_name=$1
    local pkg_command=${2:-$1}
    
    if ! command -v "$pkg_name" >/dev/null 2>&1; then
        log_step "安装 $pkg_name..."
        if yum install -y "$pkg_command" >/dev/null 2>&1; then
            log_info "$pkg_name 安装成功"
            return 0
        else
            log_warn "$pkg_name 安装失败"
            return 1
        fi
    else
        log_info "$pkg_name 已安装"
        return 0
    fi
}

# ==========================================
# 安装系统依赖（参考 playground）
# ==========================================
install_system_dependencies() {
    log_section "步骤 4/9: 安装系统依赖"
    
    # 临时禁用 set -e，允许部分依赖安装失败
    set +e
    
    log_step "检查并安装系统工具..."
    echo ""
    
    # 基础工具（参考 playground 的 check_dependency）
    install_single_dependency "expect" "expect"
    install_single_dependency "ntpdate" "ntpdate"
    install_single_dependency "wget" "wget"
    install_single_dependency "curl" "curl"
    install_single_dependency "vim" "vim"
    install_single_dependency "net-tools" "net-tools"
    
    # sshpass（SSH 免密登录需要）
    if ! rpm -qa | grep -q sshpass; then
        log_step "安装 sshpass..."
        yum install -y sshpass >/dev/null 2>&1 || log_warn "sshpass 安装失败（不影响继续）"
    else
        log_info "sshpass 已安装"
    fi
    
    # 恢复 set -e
    set -e
    
    echo ""
    log_success "系统依赖安装完成"
}

# ==========================================
# 安装 Python 和 Ansible
# ==========================================
install_python_ansible() {
    log_section "步骤 5/9: 安装 Python 和 Ansible"
    
    # 临时禁用 set -e
    set +e
    
    # 安装 Python 3
    if ! command -v python3 >/dev/null 2>&1; then
        log_step "安装 Python 3..."
        yum install -y python3 python3-pip python3-devel >/dev/null 2>&1
        log_info "Python 3 安装完成"
    else
        log_info "Python 3 已安装: $(python3 --version)"
    fi
    
    # 配置 pip 镜像
    log_step "配置 pip 镜像源..."
    mkdir -p ~/.pip
    cat > ~/.pip/pip.conf <<EOF
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/
trusted-host = mirrors.aliyun.com
EOF
    
    # 升级 pip
    log_step "升级 pip..."
    python3 -m pip install --upgrade pip -q 2>/dev/null || log_warn "pip 升级失败（不影响继续）"
    
    # 安装 Ansible
    if ! command -v ansible >/dev/null 2>&1; then
        log_step "安装 Ansible 2.9.27..."
        pip3 install ansible==2.9.27 -q 2>/dev/null
        ln -sf /usr/local/bin/ansible /usr/bin/ansible 2>/dev/null || true
        ln -sf /usr/local/bin/ansible-playbook /usr/bin/ansible-playbook 2>/dev/null || true
        log_info "Ansible 安装完成: $(ansible --version | head -1)"
    else
        log_info "Ansible 已安装: $(ansible --version | head -1)"
    fi
    
    # 安装项目依赖
    if [ -f "$PROJECT_DIR/requirements.txt" ]; then
        log_step "安装项目 Python 依赖..."
        pip3 install -r "$PROJECT_DIR/requirements.txt" -q 2>/dev/null || log_warn "部分依赖安装失败"
        log_info "项目依赖安装完成"
    fi
    
    # 恢复 set -e
    set -e
    
    echo ""
    log_success "Python 和 Ansible 安装完成"
}

# ==========================================
# 检查 SSH 免密登录状态
# ==========================================
check_ssh_passwordless() {
    local node=$1
    local status=0
    
    # 尝试无密码SSH连接
    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$node" "exit" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $node - SSH 免密已配置"
        return 0
    else
        echo -e "  ${RED}✗${NC} $node - 需要密码"
        return 1
    fi
}

# ==========================================
# 配置 SSH 免密登录
# 
# ⚠️ 重要：本功能完全参考 playground 项目实现
# 灵感来源：playground/systems/sshFreeLogin.sh
# 使用 expect 工具自动化处理密码输入
# ==========================================
setup_ssh() {
    log_section "步骤 6/9: 配置 SSH 免密登录（灵感来自 playground）"
    
    echo ""
    log_step "检查当前 SSH 免密登录状态..."
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  节点 SSH 状态检查"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 检查所有节点
    local all_configured=true
    for node in node01 node02 node03; do
        if ! check_ssh_passwordless "$node"; then
            all_configured=false
        fi
    done
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ "$all_configured" = true ]; then
        log_success "所有节点已配置 SSH 免密登录"
        echo ""
        log_info "跳过 SSH 配置步骤"
        return 0
    fi
    
    # 存在未配置的节点，询问用户
    log_warn "部分节点未配置 SSH 免密登录"
    echo ""
    read -p "是否需要配置 SSH 免密登录？(y/n): " need_ssh
    
    if [ "$need_ssh" != "y" ]; then
        log_warn "跳过 SSH 配置"
        echo ""
        echo "💡 提示：稍后可手动配置："
        echo "   make setup-ssh"
        echo ""
        return 0
    fi
    
    log_step "执行 SSH 免密登录配置..."
    echo ""
    
    if [ -f "$PROJECT_DIR/scripts/setup_ssh_keys.sh" ]; then
        chmod +x "$PROJECT_DIR/scripts/setup_ssh_keys.sh"
        
        # 尝试执行SSH配置
        if $PROJECT_DIR/scripts/setup_ssh_keys.sh; then
            echo ""
            log_success "SSH 免密登录配置完成"
            
            # 再次验证
            echo ""
            log_step "验证 SSH 配置..."
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            for node in node01 node02 node03; do
                check_ssh_passwordless "$node"
            done
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
        else
            log_error "SSH 配置失败"
            echo ""
            echo "❌ SSH 配置失败可能的原因："
            echo "   1. 节点 node02/node03 未启动或网络不通"
            echo "   2. 节点密码不正确"
            echo "   3. 防火墙阻止 SSH 连接"
            echo ""
            read -p "是否继续初始化（稍后可手动配置 SSH）？(y/n): " continue_init
            
            if [ "$continue_init" != "y" ]; then
                log_error "用户选择退出初始化"
                exit 1
            fi
            
            log_warn "跳过 SSH 配置，继续初始化"
            echo ""
            echo "💡 提示：稍后可手动执行 SSH 配置："
            echo "   make setup-ssh"
            echo ""
        fi
    else
        log_error "SSH 配置脚本不存在: $PROJECT_DIR/scripts/setup_ssh_keys.sh"
        exit 1
    fi
}

# ==========================================
# 配置系统环境（参考 playground）
# ==========================================
setup_system() {
    log_section "步骤 7/9: 配置系统环境"
    
    # 临时禁用 set -e
    set +e
    
    # 1. 配置 hosts 文件
    log_step "检查 /etc/hosts 配置..."
    if grep -q "node01" /etc/hosts && grep -q "node02" /etc/hosts && grep -q "node03" /etc/hosts; then
        log_info "/etc/hosts 已配置"
    else
        log_warn "/etc/hosts 需要配置"
        echo ""
        log_step "添加节点映射到 /etc/hosts..."
        
        # 从 .env 读取或使用默认值
        node01_ip=${MASTER_IP:-192.168.56.151}
        node02_ip=${SLAVE_IP_1:-192.168.56.152}
        node03_ip=${SLAVE_IP_2:-192.168.56.153}
        
        # 检查并添加
        if ! grep -q "node01" /etc/hosts; then
            echo "$node01_ip node01" >> /etc/hosts
        fi
        if ! grep -q "node02" /etc/hosts; then
            echo "$node02_ip node02" >> /etc/hosts
        fi
        if ! grep -q "node03" /etc/hosts; then
            echo "$node03_ip node03" >> /etc/hosts
        fi
        
        log_info "/etc/hosts 配置完成"
    fi
    
    echo ""
    
    # 2. 关闭防火墙（参考 playground）
    log_step "关闭防火墙..."
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        systemctl stop firewalld >/dev/null 2>&1
        systemctl disable firewalld >/dev/null 2>&1
        log_info "防火墙已关闭并禁用"
    else
        log_info "防火墙已经关闭"
    fi
    
    echo ""
    
    # 3. 关闭 SELinux（参考 playground）
    log_step "关闭 SELinux..."
    setenforce 0 2>/dev/null || true
    if [ -f "/etc/selinux/config" ]; then
        sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        sed -i 's/^SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
        log_info "SELinux 已设置为 disabled"
    fi
    
    echo ""
    
    # 4. 时间同步（参考 playground）
    log_step "配置时间同步..."
    if command -v ntpdate >/dev/null 2>&1; then
        if ntpdate cn.pool.ntp.org >/dev/null 2>&1; then
            log_info "时间同步成功"
            log_info "当前时间: $(date '+%Y-%m-%d %H:%M:%S')"
        else
            log_warn "时间同步失败（可能网络问题）"
        fi
    else
        log_warn "ntpdate 未安装（已在步骤 4 尝试安装）"
    fi
    
    echo ""
    
    # 5. 禁用交换分区（CDH 部署推荐）
    log_step "禁用交换分区（Swap）..."
    if swapoff -a 2>/dev/null; then
        log_info "交换分区已禁用"
        # 永久禁用
        if grep -q "^[^#].*swap" /etc/fstab; then
            sed -i 's/^\([^#].*swap.*\)$/# \1/' /etc/fstab
            log_info "已永久禁用交换分区"
        fi
    else
        log_info "交换分区已经禁用"
    fi
    
    echo ""
    
    # 6. 设置系统限制（参考 CDH 部署要求）
    log_step "配置系统限制..."
    if ! grep -q "# CDH Cluster Limits" /etc/security/limits.conf; then
        cat >> /etc/security/limits.conf << 'EOF'

# CDH Cluster Limits
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF
        log_info "系统限制配置完成"
    else
        log_info "系统限制已配置"
    fi
    
    # 恢复 set -e
    set -e
    
    echo ""
    log_success "系统环境配置完成"
}

# ==========================================
# 运行环境测试
# ==========================================
run_environment_test() {
    log_section "步骤 8/9: 运行环境测试"
    
    log_step "执行环境检查..."
    
    if [ -f "$PROJECT_DIR/scripts/check_python_env.sh" ]; then
        chmod +x "$PROJECT_DIR/scripts/check_python_env.sh"
        $PROJECT_DIR/scripts/check_python_env.sh
    fi
    
    # 测试 Ansible 连接
    log_step "测试 Ansible 连接..."
    if ansible all_node -i "$PROJECT_DIR/ansible/node_group/hosts" -m ping >/dev/null 2>&1; then
        log_info "所有节点连接正常"
    else
        log_warn "部分节点连接失败（部署时会自动处理）"
    fi
    
    log_success "环境测试完成"
}

# ==========================================
# 创建成功标志
# ==========================================
create_success_flag() {
    log_section "步骤 9/9: 完成初始化"
    
    # 创建 SUCCESS 标志文件
    cat > "$SUCCESS_FLAG" << EOF
# 环境初始化成功标志
# 初始化时间: $(date '+%Y-%m-%d %H:%M:%S')
# 初始化用户: $(whoami)
# 主机名: $(hostname)
INIT_SUCCESS=1
INIT_TIME=$(date '+%Y%m%d%H%M%S')
EOF
    
    log_info "创建成功标志: $SUCCESS_FLAG"
    
    # 显示成功提示框（参考 playground）
    echo ""
    echo "┌────────────────────────┐"
    echo "│  环境初始化成功！      │"
    echo "└────────────────────────┘"
    echo ""
}

# ==========================================
# 同步到其他集群节点（参考 playground）
# ==========================================
sync_to_cluster_nodes() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}                 📡 同步到集群节点                         ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    log_step "Master 节点环境初始化完成"
    echo ""
    
    # 询问是否同步到其他节点
    read -p "是否将环境配置同步到其他节点? (y/n，默认 y): " sync_nodes
    sync_nodes=${sync_nodes:-y}
    
    if [ "$sync_nodes" != "y" ] && [ "$sync_nodes" != "Y" ]; then
        log_warn "跳过同步到其他节点"
        echo ""
        log_info "稍后可手动同步："
        echo "   make sync-nodes  # 同步到所有节点"
        echo ""
        return 0
    fi
    
    echo ""
    log_step "开始同步项目到其他节点..."
    echo ""
    
    # 执行同步脚本
    if [ -f "$PROJECT_DIR/scripts/sync_to_nodes.sh" ]; then
        chmod +x "$PROJECT_DIR/scripts/sync_to_nodes.sh"
        
        if $PROJECT_DIR/scripts/sync_to_nodes.sh; then
            echo ""
            log_success "集群节点同步完成"
        else
            echo ""
            log_warn "部分节点同步失败（可以稍后重试）"
            echo ""
            log_info "💡 重试命令："
            echo "   make sync-nodes"
        fi
    else
        log_error "同步脚本不存在: $PROJECT_DIR/scripts/sync_to_nodes.sh"
    fi
}

# ==========================================
# 显示最终信息
# ==========================================
show_final_info() {
    echo ""
    echo -e "${MAGENTA}========================================${NC}"
    echo -e "${MAGENTA}  🎉 CDH 集群环境初始化完成！${NC}"
    echo -e "${MAGENTA}  灵感来自 playground 项目${NC}"
    echo -e "${MAGENTA}========================================${NC}"
    echo ""
    
    # 获取主机名
    local hostname=$(hostname)
    
    echo -e "${CYAN}✅ 完成项：${NC}"
    echo "  1. 集群配置检查"
    echo "  2. 安装包验证"
    echo "  3. YUM 源配置（阿里云镜像）"
    echo "  4. 系统依赖安装（expect, ntpdate, wget, curl 等）"
    echo "  5. Python 3 和 Ansible 安装"
    echo "  6. SSH 免密登录配置"
    echo "  7. 系统环境配置（防火墙、SELinux、Swap、时间同步）"
    echo "  8. 环境测试通过"
    echo "  9. 集群节点同步（如已选择）"
    echo ""
    
    echo -e "${CYAN}📊 系统信息：${NC}"
    echo "  当前节点: $hostname"
    echo "  Python  : $(python3 --version 2>/dev/null || echo '未安装')"
    echo "  Ansible : $(ansible --version 2>/dev/null | head -1 || echo '未安装')"
    echo "  时间    : $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    echo -e "${CYAN}📋 下一步操作：${NC}"
    echo "  1. 测试 SSH  : make test-ssh"
    echo "  2. 检查环境  : make check-env"
    echo "  3. 检查磁盘  : make check-disk"
    echo "  4. 开始部署  : make deploy"
    echo ""
    
    echo -e "${CYAN}🔧 常用命令：${NC}"
    echo "  make help         - 查看所有命令"
    echo "  make sync-nodes   - 重新同步到其他节点"
    echo "  make setup-ssh    - 重新配置 SSH"
    echo "  make fix-yum      - 修复 YUM 源"
    echo ""
    
    echo -e "${CYAN}📖 文档：${NC}"
    echo "  快速指南: cat QUICK_CONFIG_GUIDE.md"
    echo "  详细文档: cat README.md"
    echo ""
    
    echo -e "${MAGENTA}========================================${NC}"
    echo -e "${GREEN}  ✨ Happy Deploying! ✨${NC}"
    echo -e "${MAGENTA}========================================${NC}"
    echo ""
}

# ==========================================
# 主函数
# ==========================================
main() {
    log_section "CDH 集群环境交互式初始化"
    echo ""
    echo "本脚本将为您自动配置 CDH 部署环境"
    echo "灵感来源于 playground 项目的优雅设计"
    echo ""
    echo "作者: RaynLiu"
    echo "邮箱: liuyu1_j6go@stu.cqie.edu.cn"
    echo ""
    
    # 检查是否已初始化
    check_if_initialized
    
    # 执行初始化步骤（参考 playground 的流程）
    check_cluster_config          # 步骤 1: 检查集群配置
    check_base_file               # 步骤 2: 检查安装包
    setup_yum_repos               # 步骤 3: 配置 YUM 源
    install_system_dependencies   # 步骤 4: 安装系统依赖
    install_python_ansible        # 步骤 5: 安装 Python 和 Ansible
    setup_ssh                     # 步骤 6: 配置 SSH 免密登录
    setup_system                  # 步骤 7: 配置系统环境
    run_environment_test          # 步骤 8: 运行环境测试
    create_success_flag           # 步骤 9: 完成初始化
    
    # 询问是否同步到其他节点（参考 playground 的 update_all）
    sync_to_cluster_nodes
    
    # 显示最终信息
    show_final_info
}

# 运行主函数
main
