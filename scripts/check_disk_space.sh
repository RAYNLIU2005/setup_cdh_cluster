#!/bin/bash
# 磁盘空间检查脚本
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

# 配置阈值
CRITICAL_THRESHOLD=5    # 5GB 临界值
WARNING_THRESHOLD=10    # 10GB 警告值
RECOMMENDED_THRESHOLD=20 # 20GB 推荐值

print_header() {
    echo ""
    echo "=========================================="
    echo "  $1"
    echo "=========================================="
    echo ""
}

check_path_space() {
    local path=$1
    local name=$2
    
    # 获取可用空间（GB）
    local available=$(df -BG "$path" 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/G//')
    local total=$(df -BG "$path" 2>/dev/null | tail -1 | awk '{print $2}' | sed 's/G//')
    local used=$(df -BG "$path" 2>/dev/null | tail -1 | awk '{print $3}' | sed 's/G//')
    local percent=$(df -h "$path" 2>/dev/null | tail -1 | awk '{print $5}')
    
    echo -e "${BLUE}$name${NC} ($path)"
    echo "  总计: ${total}GB"
    echo "  已用: ${used}GB ($percent)"
    echo "  可用: ${available}GB"
    
    # 判断状态
    if [ "$available" -lt "$CRITICAL_THRESHOLD" ]; then
        echo -e "  状态: ${RED}✗ 严重不足${NC}"
        echo -e "  建议: ${RED}立即清理磁盘！${NC}"
        return 2
    elif [ "$available" -lt "$WARNING_THRESHOLD" ]; then
        echo -e "  状态: ${YELLOW}⚠ 空间紧张${NC}"
        echo -e "  建议: ${YELLOW}建议清理部分文件${NC}"
        return 1
    elif [ "$available" -lt "$RECOMMENDED_THRESHOLD" ]; then
        echo -e "  状态: ${GREEN}✓ 可用（偏紧）${NC}"
        echo -e "  建议: ${YELLOW}有条件建议扩容${NC}"
        return 0
    else
        echo -e "  状态: ${GREEN}✓ 充足${NC}"
        return 0
    fi
}

show_disk_usage_tips() {
    print_header "磁盘使用建议"
    
    echo "📊 磁盘空间要求："
    echo "  • 测试环境（最低）：5GB 可用空间"
    echo "  • 开发环境（建议）：10GB 可用空间"
    echo "  • 生产环境（推荐）：20GB+ 可用空间"
    echo ""
    
    echo "🧹 磁盘清理建议："
    echo "  1. 清理日志文件："
    echo "     sudo find /var/log -name '*.log' -mtime +7 -delete"
    echo ""
    echo "  2. 清理 YUM 缓存："
    echo "     sudo yum clean all"
    echo ""
    echo "  3. 清理临时文件："
    echo "     sudo rm -rf /tmp/*"
    echo ""
    echo "  4. 清理旧的 CDH 数据（如果有）："
    echo "     make delall"
    echo ""
}

find_large_files() {
    print_header "查找大文件"
    
    echo "正在查找大于 100MB 的文件..."
    echo ""
    
    find / -type f -size +100M 2>/dev/null | head -10 | while read file; do
        local size=$(du -h "$file" 2>/dev/null | cut -f1)
        echo "  $size - $file"
    done
    
    echo ""
    echo "提示：使用以下命令查看目录大小："
    echo "  du -h --max-depth=1 / | sort -hr | head -20"
}

main() {
    print_header "磁盘空间检查"
    
    echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # 检查关键路径
    local critical=0
    local warning=0
    
    check_path_space "/" "根分区"
    local result=$?
    [ $result -eq 2 ] && ((critical++))
    [ $result -eq 1 ] && ((warning++))
    
    echo ""
    
    if [ -d "/opt" ]; then
        check_path_space "/opt" "opt 分区"
        result=$?
        [ $result -eq 2 ] && ((critical++))
        [ $result -eq 1 ] && ((warning++))
        echo ""
    fi
    
    if [ -d "/var" ]; then
        check_path_space "/var" "var 分区"
        result=$?
        [ $result -eq 2 ] && ((critical++))
        [ $result -eq 1 ] && ((warning++))
        echo ""
    fi
    
    # 显示汇总
    print_header "检查汇总"
    
    if [ $critical -gt 0 ]; then
        echo -e "${RED}✗ 发现 $critical 个分区空间严重不足${NC}"
        echo -e "${RED}⚠️ 无法继续部署，请先清理磁盘！${NC}"
        echo ""
        show_disk_usage_tips
        find_large_files
        return 1
    elif [ $warning -gt 0 ]; then
        echo -e "${YELLOW}⚠ 发现 $warning 个分区空间紧张${NC}"
        echo -e "${YELLOW}建议清理后再部署${NC}"
        echo ""
        show_disk_usage_tips
        return 0
    else
        echo -e "${GREEN}✓ 所有分区空间充足${NC}"
        echo ""
        return 0
    fi
}

main
