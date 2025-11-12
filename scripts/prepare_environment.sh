#!/bin/bash
# ==========================================
# CDH 集群环境准备脚本
# Copyright © 2025 RaynLiu
# 保留所有权利 All Rights Reserved
# ==========================================
#
# 功能：检查并准备 CDH 集群部署所需环境
# 用法：./prepare_environment.sh
# ==========================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示版权信息
echo ""
echo "=========================================="
echo "  CDH 集群环境准备工具"
echo "  Copyright © 2025 RaynLiu"
echo "  保留所有权利 All Rights Reserved"
echo "=========================================="
echo ""

# 计数器
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# 检查函数
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNING_CHECKS++))
    ((TOTAL_CHECKS++))
}

section_header() {
    echo ""
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}===================================================${NC}"
}

# ==========================================
# 1. 系统基础检查
# ==========================================
section_header "1. 系统基础检查"

# 检查操作系统
if [ -f /etc/redhat-release ]; then
    OS_VERSION=$(cat /etc/redhat-release)
    echo "操作系统: $OS_VERSION"
    if [[ $OS_VERSION == *"CentOS Linux release 7"* ]]; then
        check_pass "CentOS 7.x"
    else
        check_warn "建议使用 CentOS 7.x"
    fi
else
    check_fail "不是 CentOS/RHEL 系统"
fi

# 检查 root 权限
if [ "$EUID" -eq 0 ]; then
    check_pass "root 权限"
else
    check_fail "需要 root 权限运行"
fi

# 检查磁盘空间
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
DISK_AVAIL=$(df -h / | tail -1 | awk '{print $4}')
echo "磁盘使用率: ${DISK_USAGE}% (可用: ${DISK_AVAIL})"
if [ "$DISK_USAGE" -lt 70 ]; then
    check_pass "磁盘空间充足"
elif [ "$DISK_USAGE" -lt 85 ]; then
    check_warn "磁盘空间紧张，建议清理"
else
    check_fail "磁盘空间不足，必须清理"
fi

# 检查内存
TOTAL_MEM=$(free -h | grep Mem | awk '{print $2}')
echo "总内存: $TOTAL_MEM"
TOTAL_MEM_GB=$(free -g | grep Mem | awk '{print $2}')
if [ "$TOTAL_MEM_GB" -ge 8 ]; then
    check_pass "内存充足 (${TOTAL_MEM})"
else
    check_warn "内存建议 >= 8GB，当前: ${TOTAL_MEM}"
fi

# 检查 CPU 核心数
CPU_CORES=$(nproc)
echo "CPU 核心数: $CPU_CORES"
if [ "$CPU_CORES" -ge 4 ]; then
    check_pass "CPU 核心充足"
else
    check_warn "CPU 建议 >= 4 核，当前: ${CPU_CORES}"
fi

# ==========================================
# 2. 网络配置检查
# ==========================================
section_header "2. 网络配置检查"

# 检查 hostname
HOSTNAME=$(hostname)
echo "主机名: $HOSTNAME"
if [[ $HOSTNAME == node* ]]; then
    check_pass "hostname 格式正确"
else
    check_warn "hostname 建议命名为 node01, node02 等"
fi

# 检查 /etc/hosts
echo "检查 /etc/hosts 配置..."
HOSTS_COUNT=$(grep -c "^[0-9].*node[0-9]" /etc/hosts 2>/dev/null || echo 0)
if [ "$HOSTS_COUNT" -ge 3 ]; then
    check_pass "hosts 文件已配置 (${HOSTS_COUNT} 条记录)"
    echo "内容预览:"
    grep "^[0-9].*node[0-9]" /etc/hosts | head -3
else
    check_fail "hosts 文件未正确配置"
    echo "  需要添加如下配置到 /etc/hosts:"
    echo "  192.168.56.151  node01"
    echo "  192.168.56.152  node02"
    echo "  192.168.56.153  node03"
fi

# 检查网络连通性
if [ -f /etc/hosts ]; then
    NODES=$(grep "^[0-9].*node[0-9]" /etc/hosts | awk '{print $2}')
    echo "检查节点连通性..."
    for node in $NODES; do
        if ping -c 1 -W 2 $node &>/dev/null; then
            check_pass "$node 可达"
        else
            check_fail "$node 不可达"
        fi
    done
fi

# 检查 SSH 免密登录
section_header "3. SSH 免密登录检查"

if [ -f ~/.ssh/id_rsa ]; then
    check_pass "SSH 密钥已生成"
else
    check_fail "SSH 密钥未生成"
    echo "  运行: ssh-keygen -t rsa"
fi

if [ -f ~/.ssh/authorized_keys ]; then
    KEY_COUNT=$(wc -l < ~/.ssh/authorized_keys)
    check_pass "authorized_keys 存在 (${KEY_COUNT} 个密钥)"
else
    check_fail "authorized_keys 不存在"
fi

# 测试免密登录
if [ -f /etc/hosts ]; then
    NODES=$(grep "^[0-9].*node[0-9]" /etc/hosts | awk '{print $2}')
    echo "测试免密登录..."
    for node in $NODES; do
        if ssh -o BatchMode=yes -o ConnectTimeout=5 $node "echo ok" &>/dev/null; then
            check_pass "$node 免密登录成功"
        else
            check_fail "$node 免密登录失败"
            echo "  运行: ssh-copy-id root@$node"
        fi
    done
fi

# ==========================================
# 4. 软件依赖检查
# ==========================================
section_header "4. 软件依赖检查"

# 检查 Ansible
if command -v ansible &>/dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -1)
    check_pass "Ansible 已安装 - $ANSIBLE_VERSION"
else
    check_fail "Ansible 未安装"
    echo "  安装: yum install -y centos-release-ansible-28.noarch && yum install -y ansible"
fi

# 检查 Python
if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 --version)
    check_pass "Python 3 已安装 - $PYTHON_VERSION"
else
    check_warn "Python 3 未安装（部署时会自动安装）"
fi

# 检查 pip3
if command -v pip3 &>/dev/null; then
    PIP_VERSION=$(pip3 --version | cut -d' ' -f2)
    check_pass "pip3 已安装 - v$PIP_VERSION"
else
    check_warn "pip3 未安装（部署时会自动安装）"
fi

# 检查必要的系统工具
for cmd in tar gzip wget curl rsync; do
    if command -v $cmd &>/dev/null; then
        check_pass "$cmd 已安装"
    else
        check_fail "$cmd 未安装"
    fi
done

# ==========================================
# 5. 目录结构检查
# ==========================================
section_header "5. 目录结构检查"

# 检查项目目录
if [ -d "/root/setup_cdh_cluster" ]; then
    check_pass "项目目录存在: /root/setup_cdh_cluster"
    
    # 检查关键文件
    if [ -f "/root/setup_cdh_cluster/Makefile" ]; then
        check_pass "Makefile 存在"
    else
        check_fail "Makefile 不存在"
    fi
    
    if [ -d "/root/setup_cdh_cluster/ansible" ]; then
        check_pass "ansible 目录存在"
    else
        check_fail "ansible 目录不存在"
    fi
    
    if [ -d "/root/setup_cdh_cluster/scripts" ]; then
        check_pass "scripts 目录存在"
    else
        check_fail "scripts 目录不存在"
    fi
else
    check_fail "项目目录不存在: /root/setup_cdh_cluster"
fi

# 检查 base_file 目录
echo ""
echo "检查安装包目录..."
if [ -d "/opt/base_file" ]; then
    check_pass "/opt/base_file 目录存在"
else
    check_fail "/opt/base_file 目录不存在"
    echo "  创建: mkdir -p /opt/base_file/{packages,parcels}"
fi

if [ -d "/opt/base_file/packages" ]; then
    PKG_COUNT=$(ls -1 /opt/base_file/packages 2>/dev/null | wc -l)
    PKG_SIZE=$(du -sh /opt/base_file/packages 2>/dev/null | cut -f1)
    if [ "$PKG_COUNT" -gt 0 ]; then
        check_pass "packages 目录存在 ($PKG_COUNT 个文件, $PKG_SIZE)"
    else
        check_fail "packages 目录为空"
    fi
else
    check_fail "/opt/base_file/packages 目录不存在"
fi

if [ -d "/opt/base_file/parcels" ]; then
    PARCEL_COUNT=$(ls -1 /opt/base_file/parcels 2>/dev/null | wc -l)
    PARCEL_SIZE=$(du -sh /opt/base_file/parcels 2>/dev/null | cut -f1)
    if [ "$PARCEL_COUNT" -gt 0 ]; then
        check_pass "parcels 目录存在 ($PARCEL_COUNT 个文件, $PARCEL_SIZE)"
    else
        check_fail "parcels 目录为空"
    fi
else
    check_fail "/opt/base_file/parcels 目录不存在"
fi

# ==========================================
# 6. 必需文件检查
# ==========================================
section_header "6. 必需文件检查"

echo "检查关键安装包..."

REQUIRED_FILES=(
    "jdk-8u261-linux-x64.tar.gz"
    "scala-2.13.0-M4.tgz"
    "mysql-connector-java-5.1.47.jar"
    "mysql-community-server-5.7.30-1.el7.x86_64.rpm"
    "RPM-GPG-KEY-cloudera"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "/opt/base_file/packages/$file" ]; then
        SIZE=$(ls -lh "/opt/base_file/packages/$file" | awk '{print $5}')
        check_pass "$file ($SIZE)"
    else
        check_fail "$file 不存在"
    fi
done

echo ""
echo "检查 Parcel 文件..."
PARCEL_PATTERN="CDH-6.*-el7.parcel"
if ls /opt/base_file/parcels/$PARCEL_PATTERN &>/dev/null; then
    for parcel in /opt/base_file/parcels/CDH-6*.parcel*; do
        if [ -f "$parcel" ]; then
            FILENAME=$(basename "$parcel")
            SIZE=$(ls -lh "$parcel" | awk '{print $5}')
            check_pass "$FILENAME ($SIZE)"
        fi
    done
else
    check_fail "CDH Parcel 文件不存在"
fi

# ==========================================
# 7. 防火墙和 SELinux 检查
# ==========================================
section_header "7. 安全配置检查"

# 检查防火墙状态
if systemctl is-active --quiet firewalld; then
    check_warn "防火墙正在运行（部署时会关闭）"
else
    check_pass "防火墙已关闭"
fi

# 检查 SELinux 状态
SELINUX_STATUS=$(getenforce 2>/dev/null || echo "Unknown")
if [ "$SELINUX_STATUS" = "Disabled" ] || [ "$SELINUX_STATUS" = "Permissive" ]; then
    check_pass "SELinux 已禁用/宽容模式"
else
    check_warn "SELinux 处于强制模式（部署时会调整）"
fi

# ==========================================
# 8. Ansible Inventory 检查
# ==========================================
section_header "8. Ansible 配置检查"

INVENTORY="/root/setup_cdh_cluster/ansible/node_group/hosts"
if [ -f "$INVENTORY" ]; then
    check_pass "Inventory 文件存在"
    
    echo "检查主机组配置..."
    if grep -q "\[master_node\]" "$INVENTORY"; then
        check_pass "[master_node] 组已配置"
    else
        check_fail "[master_node] 组未配置"
    fi
    
    if grep -q "\[slave_node\]" "$INVENTORY"; then
        check_pass "[slave_node] 组已配置"
    else
        check_fail "[slave_node] 组未配置"
    fi
    
    echo ""
    echo "Inventory 配置预览:"
    cat "$INVENTORY" | head -15
else
    check_fail "Inventory 文件不存在: $INVENTORY"
fi

# ==========================================
# 总结报告
# ==========================================
section_header "检查总结"

echo ""
echo "检查完成统计:"
echo -e "  ${GREEN}通过: ${PASSED_CHECKS}${NC}"
echo -e "  ${YELLOW}警告: ${WARNING_CHECKS}${NC}"
echo -e "  ${RED}失败: ${FAILED_CHECKS}${NC}"
echo -e "  总计: ${TOTAL_CHECKS}"
echo ""

# 判断是否可以部署
if [ "$FAILED_CHECKS" -eq 0 ]; then
    if [ "$WARNING_CHECKS" -eq 0 ]; then
        echo -e "${GREEN}=========================================="
        echo -e "  ✓ 环境准备完美！可以开始部署"
        echo -e "==========================================${NC}"
        echo ""
        echo "下一步："
        echo "  cd /root/setup_cdh_cluster"
        echo "  make deploy"
    else
        echo -e "${YELLOW}=========================================="
        echo -e "  ⚠ 环境基本就绪，但有 ${WARNING_CHECKS} 个警告"
        echo -e "==========================================${NC}"
        echo ""
        echo "建议："
        echo "  1. 查看上述警告信息"
        echo "  2. 修复非关键问题"
        echo "  3. 或直接部署: cd /root/setup_cdh_cluster && make deploy"
    fi
else
    echo -e "${RED}=========================================="
    echo -e "  ✗ 环境准备不完整！有 ${FAILED_CHECKS} 个错误"
    echo -e "==========================================${NC}"
    echo ""
    echo "请先修复上述错误，然后重新运行此脚本检查"
fi

echo ""
echo "详细准备指南："
echo "  cat /root/setup_cdh_cluster/ENVIRONMENT_SETUP.md"
echo ""
