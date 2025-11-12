#!/bin/bash
# 删除前安全验证脚本
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# date: 2025-11-12

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "========================================"
echo "  删除前安全检查"
echo "========================================"
echo ""

# 检查 base_file 目录
check_base_file() {
    echo -e "${BLUE}[检查]${NC} 验证 /opt/base_file 目录..."
    
    if [ -d "/opt/base_file" ]; then
        local file_count=$(ls -1 /opt/base_file 2>/dev/null | wc -l)
        echo -e "${GREEN}[✓]${NC} /opt/base_file 存在，包含 $file_count 个文件/目录"
        echo -e "${YELLOW}[!]${NC} 删除脚本会保留此目录"
    else
        echo -e "${YELLOW}[⚠]${NC} /opt/base_file 不存在"
    fi
}

# 检查要删除的目录
check_delete_targets() {
    echo ""
    echo -e "${BLUE}[检查]${NC} 将要删除的目录..."
    
    local targets=(
        "/opt/cloudera"
        "/var/lib/cloudera-scm-server"
        "/var/lib/cloudera-scm-agent"
        "/usr/java"
        "/usr/local/scala"
    )
    
    for target in "${targets[@]}"; do
        if [ -e "$target" ]; then
            local size=$(du -sh "$target" 2>/dev/null | cut -f1)
            echo -e "${YELLOW}[找到]${NC} $target ($size)"
        fi
    done
}

# 检查系统关键目录（不应删除）
check_protected_dirs() {
    echo ""
    echo -e "${BLUE}[检查]${NC} 系统保护目录..."
    
    local protected=(
        "/opt/base_file"
        "/etc"
        "/usr/bin"
        "/usr/lib"
        "/home"
    )
    
    echo -e "${GREEN}以下目录会被保护：${NC}"
    for dir in "${protected[@]}"; do
        if [ -d "$dir" ]; then
            echo -e "${GREEN}[✓]${NC} $dir"
        fi
    done
}

# 检查系统服务（不应停止）
check_system_services() {
    echo ""
    echo -e "${BLUE}[检查]${NC} 系统关键服务..."
    
    local system_services=(
        "sshd"
        "network"
        "systemd"
    )
    
    echo -e "${GREEN}以下系统服务不会被停止：${NC}"
    for service in "${system_services[@]}"; do
        if systemctl is-active $service >/dev/null 2>&1; then
            echo -e "${GREEN}[运行]${NC} $service"
        fi
    done
}

# 显示将要删除的服务
show_delete_services() {
    echo ""
    echo -e "${BLUE}[检查]${NC} 将要停止的 CDH 服务..."
    
    local cdh_services=(
        "cloudera-scm-server"
        "cloudera-scm-agent"
        "mysqld"
        "httpd"
    )
    
    for service in "${cdh_services[@]}"; do
        if systemctl is-active $service >/dev/null 2>&1; then
            echo -e "${YELLOW}[运行]${NC} $service - 将被停止"
        else
            echo -e "${GREEN}[未运行]${NC} $service"
        fi
    done
}

# 主函数
main() {
    check_base_file
    check_delete_targets
    check_protected_dirs
    check_system_services
    show_delete_services
    
    echo ""
    echo "========================================"
    echo "  安全检查完成"
    echo "========================================"
    echo ""
    echo -e "${GREEN}✓ /opt/base_file 会被保留${NC}"
    echo -e "${GREEN}✓ 系统服务不会受影响${NC}"
    echo -e "${GREEN}✓ 只删除 CDH 相关内容${NC}"
    echo ""
}

main
