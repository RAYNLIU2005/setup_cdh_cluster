#!/bin/bash
# CDH 集群系统性能优化脚本
# 优化项：禁用透明大页、调整 swappiness
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_header() {
    echo ""
    echo "=========================================="
    echo "  CDH 集群系统性能优化"
    echo "=========================================="
    echo ""
}

# 获取当前主机名
CURRENT_HOST=$(hostname)

# 禁用透明大页
disable_transparent_hugepage() {
    log_info "禁用透明大页（Transparent Huge Pages）..."
    
    # 检查是否支持透明大页
    if [ ! -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
        log_warning "系统不支持透明大页，跳过"
        return 0
    fi
    
    # 临时禁用
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
    echo never > /sys/kernel/mm/transparent_hugepage/defrag
    
    # 验证
    local thp_enabled=$(cat /sys/kernel/mm/transparent_hugepage/enabled)
    if [[ $thp_enabled == *"[never]"* ]]; then
        log_success "透明大页已禁用（临时生效）"
    else
        log_error "透明大页禁用失败"
        return 1
    fi
    
    # 永久禁用 - 添加到 rc.local
    log_info "配置开机自动禁用透明大页..."
    
    # 确保 rc.local 存在
    if [ ! -f /etc/rc.d/rc.local ]; then
        touch /etc/rc.d/rc.local
    fi
    
    # 检查是否已经配置
    if ! grep -q "transparent_hugepage" /etc/rc.local; then
        cat >> /etc/rc.local << 'EOF'

# 禁用透明大页（CDH 性能优化）
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
    echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
EOF
        log_success "透明大页禁用配置已添加到 /etc/rc.local"
    else
        log_info "透明大页禁用配置已存在于 /etc/rc.local"
    fi
    
    # 确保 rc.local 有执行权限
    chmod +x /etc/rc.d/rc.local
    
    return 0
}

# 调整 swappiness
adjust_swappiness() {
    log_info "调整 swappiness 值..."
    
    local current_swappiness=$(cat /proc/sys/vm/swappiness)
    log_info "当前 swappiness 值: $current_swappiness"
    
    # Cloudera 推荐值为 1
    local target_swappiness=1
    
    # 临时调整
    sysctl -w vm.swappiness=$target_swappiness >/dev/null 2>&1
    
    # 验证
    local new_swappiness=$(cat /proc/sys/vm/swappiness)
    if [ "$new_swappiness" -eq "$target_swappiness" ]; then
        log_success "swappiness 已设置为 $target_swappiness（临时生效）"
    else
        log_error "swappiness 调整失败"
        return 1
    fi
    
    # 永久保存到 sysctl.conf
    log_info "保存 swappiness 配置到 /etc/sysctl.conf..."
    
    if grep -q "^vm.swappiness" /etc/sysctl.conf; then
        # 已存在，修改
        sed -i "s/^vm.swappiness.*/vm.swappiness = $target_swappiness/" /etc/sysctl.conf
        log_success "swappiness 配置已更新"
    else
        # 不存在，添加
        echo "vm.swappiness = $target_swappiness" >> /etc/sysctl.conf
        log_success "swappiness 配置已添加"
    fi
    
    return 0
}

# 验证优化结果
verify_optimization() {
    log_info "验证优化结果..."
    echo ""
    
    echo "  透明大页状态："
    local thp_status=$(cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null)
    if [[ $thp_status == *"[never]"* ]]; then
        echo -e "    ${GREEN}✓ 已禁用${NC} - $thp_status"
    else
        echo -e "    ${RED}✗ 未禁用${NC} - $thp_status"
    fi
    
    echo ""
    echo "  Swappiness 值："
    local swappiness_value=$(cat /proc/sys/vm/swappiness)
    if [ "$swappiness_value" -le 10 ]; then
        echo -e "    ${GREEN}✓ 合格${NC} - $swappiness_value （推荐值 ≤ 10）"
    else
        echo -e "    ${YELLOW}⚠ 偏高${NC} - $swappiness_value （推荐值 ≤ 10）"
    fi
    
    echo ""
}

# 主函数
main() {
    print_header
    
    log_info "开始优化节点: $CURRENT_HOST"
    echo ""
    
    # 执行优化
    local failed=0
    
    if ! disable_transparent_hugepage; then
        ((failed++))
    fi
    
    echo ""
    
    if ! adjust_swappiness; then
        ((failed++))
    fi
    
    echo ""
    
    # 验证结果
    verify_optimization
    
    # 总结
    echo "=========================================="
    if [ $failed -eq 0 ]; then
        log_success "节点 $CURRENT_HOST 性能优化完成！"
        echo ""
        log_info "优化项："
        echo "  ✓ 透明大页已禁用"
        echo "  ✓ Swappiness 已设置为 1"
        echo ""
        log_info "这些优化将在重启后继续生效"
    else
        log_error "节点 $CURRENT_HOST 性能优化失败！"
        exit 1
    fi
    echo "=========================================="
    echo ""
}

# 执行主函数
main
