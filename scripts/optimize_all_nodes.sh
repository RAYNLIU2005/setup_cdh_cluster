#!/bin/bash
# 批量优化所有集群节点的系统性能
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 集群节点列表
NODES=("node01" "node02" "node03")

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

echo ""
echo "=========================================="
echo "  批量优化所有集群节点性能"
echo "=========================================="
echo ""

# 统计
total_nodes=${#NODES[@]}
success_count=0
failed_nodes=()

for node in "${NODES[@]}"; do
    echo "=========================================="
    log_info "优化节点: $node"
    echo "=========================================="
    
    if [ "$node" == "$(hostname)" ] || [ "$node" == "node01" ]; then
        # 本地执行
        if bash "$SCRIPT_DIR/optimize_system_performance.sh"; then
            ((success_count++))
            log_success "节点 $node 优化成功"
        else
            log_error "节点 $node 优化失败"
            failed_nodes+=("$node")
        fi
    else
        # 远程执行
        # 先复制脚本
        if scp "$SCRIPT_DIR/optimize_system_performance.sh" "$node:/tmp/" >/dev/null 2>&1; then
            # 执行脚本
            if ssh "$node" "bash /tmp/optimize_system_performance.sh"; then
                ((success_count++))
                log_success "节点 $node 优化成功"
            else
                log_error "节点 $node 优化失败"
                failed_nodes+=("$node")
            fi
            # 清理临时文件
            ssh "$node" "rm -f /tmp/optimize_system_performance.sh" >/dev/null 2>&1
        else
            log_error "无法连接到节点 $node"
            failed_nodes+=("$node")
        fi
    fi
    
    echo ""
done

# 总结
echo "=========================================="
echo "  优化完成统计"
echo "=========================================="
echo "总节点数: $total_nodes"
echo "成功: $success_count"
echo "失败: $((total_nodes - success_count))"

if [ ${#failed_nodes[@]} -gt 0 ]; then
    echo ""
    log_error "以下节点优化失败:"
    for node in "${failed_nodes[@]}"; do
        echo "  - $node"
    done
    echo ""
    exit 1
else
    echo ""
    log_success "所有节点优化完成！"
    echo ""
    log_info "下次在 Cloudera Manager 中创建集群时，不会再看到这些警告了"
    echo ""
fi
echo "=========================================="
