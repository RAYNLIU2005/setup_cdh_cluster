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
    log_section "步骤 1/8: 检查集群配置"
    
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
    echo "当前集群配置："
    echo "======================================="
    
    # 读取并显示配置
    if [ -f "$PROJECT_DIR/.env" ]; then
        echo "节点信息："
        grep -E "^(MASTER_NODE|MASTER_IP|SLAVE_NODE)" "$PROJECT_DIR/.env" | while read line; do
            echo "  $line"
        done
        echo ""
        echo "MySQL 配置："
        grep "^MYSQL_ROOT_PASSWORD" "$PROJECT_DIR/.env" || echo "  未配置"
        echo ""
    fi
    
    echo "======================================="
    echo ""
    
    # 确认配置
    confirm=""
    while [ "$confirm" != "y" ] && [ "$confirm" != "n" ]; do
        read -p "请确认以上配置是否正确 (y/n): " confirm
    done
    
    if [ "$confirm" == "n" ]; then
        log_warn "请先编辑配置文件: vi $PROJECT_DIR/.env"
        exit 1
    fi
    
    log_success "配置确认完成"
}

# ==========================================
# 检查 base_file 目录
# ==========================================
check_base_file() {
    log_section "步骤 2/8: 检查安装包目录"
    
    if [ ! -d "/opt/base_file" ]; then
        log_error "/opt/base_file 目录不存在！"
        echo ""
        echo "请执行以下步骤："
        echo "  1. 创建目录: mkdir -p /opt/base_file/{packages,parcels}"
        echo "  2. 上传安装包到相应目录"
        echo "  3. 参考文档: doc/base_file目录准备指南.md"
        echo ""
        exit 1
    fi
    
    # 检查 packages 目录
    if [ -d "/opt/base_file/packages" ]; then
        pkg_count=$(ls -1 /opt/base_file/packages 2>/dev/null | wc -l)
        if [ $pkg_count -gt 0 ]; then
            log_info "packages 目录: $pkg_count 个文件"
        else
            log_error "packages 目录为空！"
            exit 1
        fi
    else
        log_error "/opt/base_file/packages 目录不存在！"
        exit 1
    fi
    
    # 检查 parcels 目录
    if [ -d "/opt/base_file/parcels" ]; then
        parcel_count=$(ls -1 /opt/base_file/parcels 2>/dev/null | wc -l)
        if [ $parcel_count -gt 0 ]; then
            log_info "parcels 目录: $parcel_count 个文件"
        else
            log_error "parcels 目录为空！"
            exit 1
        fi
    else
        log_error "/opt/base_file/parcels 目录不存在！"
        exit 1
    fi
    
    log_success "安装包检查完成"
}

# ==========================================
# 配置 YUM 源
# ==========================================
setup_yum_repos() {
    log_section "步骤 3/8: 配置 YUM 源"
    
    log_step "清理旧的 YUM 源配置..."
    rm -f /etc/yum.repos.d/*ansible*.repo
    rm -f /etc/yum.repos.d/CentOS-Ansible*.repo
    
    log_step "配置阿里云镜像源..."
    
    # 备份原有源
    if [ -f "/etc/yum.repos.d/CentOS-Base.repo" ]; then
        cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak.$(date +%Y%m%d)
    fi
    
    # 配置 EPEL 源
    if [ -f "/etc/yum.repos.d/epel.repo" ]; then
        sed -i 's|^metalink=|#metalink=|g' /etc/yum.repos.d/epel.repo
        sed -i 's|^#baseurl=https://download.fedoraproject.org/pub/epel|baseurl=https://mirrors.aliyun.com/epel|g' /etc/yum.repos.d/epel.repo
        sed -i '/^\[epel\]/a skip_if_unavailable=1' /etc/yum.repos.d/epel.repo
    fi
    
    log_step "清理和重建 YUM 缓存..."
    yum clean all >/dev/null 2>&1
    yum makecache fast >/dev/null 2>&1
    
    log_success "YUM 源配置完成"
}

# ==========================================
# 安装基础依赖
# ==========================================
install_dependencies() {
    log_section "步骤 4/8: 安装基础依赖"
    
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
    python3 -m pip install --upgrade pip -q
    
    # 安装 Ansible
    if ! command -v ansible >/dev/null 2>&1; then
        log_step "安装 Ansible 2.9.27..."
        pip3 install ansible==2.9.27 -q
        ln -sf /usr/local/bin/ansible /usr/bin/ansible 2>/dev/null || true
        ln -sf /usr/local/bin/ansible-playbook /usr/bin/ansible-playbook 2>/dev/null || true
        log_info "Ansible 安装完成: $(ansible --version | head -1)"
    else
        log_info "Ansible 已安装: $(ansible --version | head -1)"
    fi
    
    # 安装项目依赖
    if [ -f "$PROJECT_DIR/requirements.txt" ]; then
        log_step "安装项目 Python 依赖..."
        pip3 install -r "$PROJECT_DIR/requirements.txt" -q
        log_info "项目依赖安装完成"
    fi
    
    log_success "基础依赖安装完成"
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
# ==========================================
setup_ssh() {
    log_section "步骤 5/8: 配置 SSH 免密登录"
    
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
# 配置系统环境
# ==========================================
setup_system() {
    log_section "步骤 6/8: 配置系统环境"
    
    # 配置 hosts 文件
    log_step "检查 /etc/hosts 配置..."
    if grep -q "node01" /etc/hosts && grep -q "node02" /etc/hosts && grep -q "node03" /etc/hosts; then
        log_info "/etc/hosts 已配置"
    else
        log_warn "/etc/hosts 需要手动配置"
        echo "请确保 /etc/hosts 包含集群节点映射"
    fi
    
    # 关闭防火墙
    log_step "关闭防火墙..."
    if systemctl is-active --quiet firewalld; then
        systemctl stop firewalld >/dev/null 2>&1
        systemctl disable firewalld >/dev/null 2>&1
        log_info "防火墙已关闭"
    else
        log_info "防火墙已经关闭"
    fi
    
    # 关闭 SELinux
    log_step "关闭 SELinux..."
    setenforce 0 2>/dev/null || true
    if [ -f "/etc/selinux/config" ]; then
        sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        log_info "SELinux 已设置为 disabled"
    fi
    
    # 时间同步
    log_step "配置时间同步..."
    if command -v ntpdate >/dev/null 2>&1; then
        ntpdate cn.pool.ntp.org >/dev/null 2>&1 || true
        log_info "时间同步完成"
    else
        yum install -y ntpdate >/dev/null 2>&1
        ntpdate cn.pool.ntp.org >/dev/null 2>&1 || true
        log_info "时间同步完成"
    fi
    
    log_success "系统环境配置完成"
}

# ==========================================
# 运行环境测试
# ==========================================
run_environment_test() {
    log_section "步骤 7/8: 运行环境测试"
    
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
    log_section "步骤 8/8: 完成初始化"
    
    # 创建成功标志文件
    cat > "$SUCCESS_FLAG" <<EOF
# CDH 环境初始化成功标志
# 初始化时间: $(date '+%Y-%m-%d %H:%M:%S')
# 初始化用户: $(whoami)
# 主机名: $(hostname)
INIT_SUCCESS=1
INIT_TIME=$(date '+%Y%m%d%H%M%S')
EOF
    
    log_info "创建成功标志: $SUCCESS_FLAG"
}

# ==========================================
# 显示最终信息
# ==========================================
show_final_info() {
    echo ""
    echo -e "${MAGENTA}========================================${NC}"
    echo -e "${MAGENTA}  🎉 环境初始化完成！${NC}"
    echo -e "${MAGENTA}========================================${NC}"
    echo ""
    echo -e "${GREEN}✓ YUM 源配置${NC}"
    echo -e "${GREEN}✓ Python 3 和 Ansible 安装${NC}"
    echo -e "${GREEN}✓ 项目依赖安装${NC}"
    echo -e "${GREEN}✓ SSH 免密登录配置${NC}"
    echo -e "${GREEN}✓ 系统环境配置${NC}"
    echo -e "${GREEN}✓ 环境测试通过${NC}"
    echo ""
    echo "📋 下一步操作："
    echo "  1. 检查配置: make check"
    echo "  2. 运行测试: make test-env"
    echo "  3. 开始部署: make deploy"
    echo ""
    echo "📝 提示："
    echo "  - 重新初始化: make init"
    echo "  - 查看帮助: make help"
    echo "  - 部署文档: cat doc/快速开始指南.md"
    echo ""
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
    
    # 执行初始化步骤
    check_cluster_config
    check_base_file
    setup_yum_repos
    install_dependencies
    setup_ssh
    setup_system
    run_environment_test
    create_success_flag
    
    # 显示最终信息
    show_final_info
}

# 运行主函数
main
