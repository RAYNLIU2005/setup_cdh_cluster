#!/bin/bash
# YUM 源诊断脚本
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# date: 2025-11-12

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

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

# 检查网络连接
check_network() {
    log_section "1. 检查网络连接"
    
    # 检查基本网络
    if ping -c 2 114.114.114.114 >/dev/null 2>&1; then
        log_info "基本网络连接正常"
    else
        log_error "网络连接失败（无法访问 114.114.114.114）"
        return 1
    fi
    
    # 检查 DNS 解析
    if ping -c 2 mirrors.aliyun.com >/dev/null 2>&1; then
        log_info "DNS 解析正常（可以解析 mirrors.aliyun.com）"
    else
        log_warn "DNS 解析可能有问题"
    fi
    
    # 检查阿里云镜像源
    if curl -s --connect-timeout 5 https://mirrors.aliyun.com >/dev/null 2>&1; then
        log_info "可以访问阿里云镜像源"
    else
        log_warn "无法访问阿里云镜像源（可能需要代理）"
    fi
}

# 检查系统时间
check_time() {
    log_section "2. 检查系统时间"
    
    current_time=$(date '+%Y-%m-%d %H:%M:%S')
    log_step "当前系统时间: $current_time"
    
    # 检查时区
    timezone=$(timedatectl 2>/dev/null | grep "Time zone" | awk '{print $3}')
    if [ -n "$timezone" ]; then
        log_info "时区: $timezone"
    fi
    
    # 检查 NTP 同步
    if systemctl is-active --quiet chronyd 2>/dev/null; then
        log_info "chronyd 服务运行中"
    elif systemctl is-active --quiet ntpd 2>/dev/null; then
        log_info "ntpd 服务运行中"
    else
        log_warn "NTP 服务未运行，建议安装 ntpdate"
    fi
}

# 检查 YUM 源配置
check_yum_repos() {
    log_section "3. 检查 YUM 源配置"
    
    echo ""
    log_step "YUM 源配置文件列表:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ls -lh /etc/yum.repos.d/*.repo 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # 检查主要源文件
    if [ -f /etc/yum.repos.d/CentOS-Base.repo ]; then
        log_info "CentOS-Base.repo 存在"
        
        # 检查是否配置了阿里云镜像
        if grep -q "mirrors.aliyun.com" /etc/yum.repos.d/CentOS-Base.repo; then
            log_info "  已配置阿里云镜像源"
        else
            log_warn "  未配置阿里云镜像源"
        fi
    else
        log_error "CentOS-Base.repo 不存在！"
    fi
    
    if [ -f /etc/yum.repos.d/epel.repo ]; then
        log_info "epel.repo 存在"
    else
        log_warn "epel.repo 不存在"
    fi
    
    # 检查是否有错误的 Ansible 源
    ansible_repos=$(ls /etc/yum.repos.d/*ansible*.repo 2>/dev/null | wc -l)
    if [ $ansible_repos -gt 0 ]; then
        log_warn "发现 $ansible_repos 个 Ansible 相关源文件（可能导致冲突）"
        ls /etc/yum.repos.d/*ansible*.repo 2>/dev/null | sed 's/^/  /'
    fi
}

# 检查 YUM 缓存
check_yum_cache() {
    log_section "4. 检查 YUM 缓存"
    
    cache_dir="/var/cache/yum"
    if [ -d "$cache_dir" ]; then
        cache_size=$(du -sh $cache_dir 2>/dev/null | awk '{print $1}')
        log_info "YUM 缓存目录大小: $cache_size"
    fi
    
    # 检查缓存是否可用
    log_step "测试 YUM 缓存..."
    if yum list installed >/dev/null 2>&1; then
        log_info "YUM 缓存可用"
    else
        log_warn "YUM 缓存可能损坏"
    fi
}

# 测试 YUM 功能
test_yum() {
    log_section "5. 测试 YUM 功能"
    
    echo ""
    log_step "清理 YUM 缓存..."
    if yum clean all 2>&1 | grep -q "Cleaning"; then
        log_info "YUM 缓存清理成功"
    else
        log_error "YUM 缓存清理失败"
    fi
    
    echo ""
    log_step "重建 YUM 缓存..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 执行并显示详细输出
    if yum makecache fast 2>&1; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_info "YUM 缓存重建成功"
    else
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "YUM 缓存重建失败"
        return 1
    fi
    
    echo ""
    log_step "测试软件包查询..."
    if yum search wget >/dev/null 2>&1; then
        log_info "YUM 查询功能正常"
    else
        log_error "YUM 查询功能异常"
    fi
}

# 提供修复建议
suggest_fixes() {
    log_section "6. 修复建议"
    
    echo ""
    echo "🔧 推荐的修复步骤："
    echo ""
    echo "1. 手动修复 YUM 源:"
    echo "   make fix-yum"
    echo ""
    echo "2. 检查网络和防火墙:"
    echo "   ping mirrors.aliyun.com"
    echo "   curl -I https://mirrors.aliyun.com/centos/7/os/x86_64/"
    echo ""
    echo "3. 同步系统时间:"
    echo "   yum install -y ntpdate"
    echo "   ntpdate cn.pool.ntp.org"
    echo ""
    echo "4. 清理并重建缓存:"
    echo "   rm -rf /var/cache/yum/*"
    echo "   yum clean all"
    echo "   yum makecache fast"
    echo ""
    echo "5. 临时禁用 GPG 检查:"
    echo "   sed -i 's/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/*.repo"
    echo ""
}

# 主函数
main() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  YUM 源诊断工具${NC}"
    echo -e "${CYAN}  Copyright © 2025 RaynLiu${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    # 执行所有检查
    check_network
    check_time
    check_yum_repos
    check_yum_cache
    test_yum
    
    # 根据结果提供建议
    if [ $? -eq 0 ]; then
        echo ""
        log_section "诊断结果"
        log_info "YUM 配置正常，可以继续使用"
    else
        suggest_fixes
    fi
    
    echo ""
}

# 运行主函数
main
