#!/bin/bash
# 手动分发 CDH Parcel 脚本
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# date: 2025-11-12
# 功能：手动复制 Parcel 到所有节点

PROJECT_DIR=/root/setup_cdh_cluster
source "$PROJECT_DIR/lib/output_formatter.sh" 2>/dev/null || {
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
    log_error() { echo -e "${RED}[✗]${NC} $1"; }
    log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
    log_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
    log_step() { echo -e "${BLUE}[→]${NC} $1"; }
    print_header() { echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "  $1"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo ""; }
}

print_header "手动分发 CDH Parcel"

NODES=("node01" "node02" "node03")
PARCEL_SEARCH_DIRS=("/var/www/html/cloudera-repos/cdh6" "/opt/base_file" "/opt/setup_cdh")

# 查找 Parcel 文件
log_step "查找 Parcel 文件..."
PARCEL_FILE=""
PARCEL_SHA=""

for dir in "${PARCEL_SEARCH_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        FOUND_PARCEL=$(find "$dir" -name "CDH-*.parcel" -type f 2>/dev/null | head -1)
        if [ -n "$FOUND_PARCEL" ]; then
            PARCEL_FILE="$FOUND_PARCEL"
            PARCEL_SHA=$(find "$(dirname $FOUND_PARCEL)" -name "$(basename $FOUND_PARCEL).sha*" -type f 2>/dev/null | head -1)
            break
        fi
    fi
done

if [ -z "$PARCEL_FILE" ]; then
    log_error "未找到 Parcel 文件！"
    echo ""
    echo "请检查以下目录是否包含 CDH Parcel 文件："
    for dir in "${PARCEL_SEARCH_DIRS[@]}"; do
        echo "  - $dir"
    done
    exit 1
fi

log_success "找到 Parcel 文件:"
echo "  Parcel: $PARCEL_FILE"
echo "  SHA:    $PARCEL_SHA"
echo ""

# 获取文件大小
PARCEL_SIZE=$(du -h "$PARCEL_FILE" | awk '{print $1}')
echo "  大小:   $PARCEL_SIZE"
echo ""

read -p "是否继续分发到所有节点？[yes/no]: " confirm
if [ "$confirm" != "yes" ]; then
    log_warning "用户取消操作"
    exit 0
fi

echo ""

# 创建目录
log_step "在所有节点创建 Parcel 目录..."
for node in "${NODES[@]}"; do
    ssh $node "mkdir -p /opt/cloudera/parcel-cache /opt/cloudera/parcels" 2>/dev/null
    log_success "$node: 目录已创建"
done

echo ""

# 分发 Parcel
log_step "开始分发 Parcel..."
echo ""

for node in "${NODES[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  分发到 $node"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 检查目标节点是否已有文件
    if ssh $node "test -f /opt/cloudera/parcel-cache/$(basename $PARCEL_FILE)" 2>/dev/null; then
        log_warning "$node: Parcel 已存在，跳过"
    else
        log_step "$node: 复制 Parcel 文件... (这可能需要几分钟)"
        if scp -q "$PARCEL_FILE" "$node:/opt/cloudera/parcel-cache/"; then
            log_success "$node: Parcel 复制完成"
        else
            log_error "$node: Parcel 复制失败"
            continue
        fi
    fi
    
    # 复制 SHA 文件
    if [ -n "$PARCEL_SHA" ]; then
        if ssh $node "test -f /opt/cloudera/parcel-cache/$(basename $PARCEL_SHA)" 2>/dev/null; then
            log_warning "$node: SHA 文件已存在，跳过"
        else
            log_step "$node: 复制 SHA 文件..."
            if scp -q "$PARCEL_SHA" "$node:/opt/cloudera/parcel-cache/"; then
                log_success "$node: SHA 文件复制完成"
            else
                log_error "$node: SHA 文件复制失败"
            fi
        fi
    fi
    
    # 设置权限
    log_step "$node: 设置权限..."
    ssh $node "chown -R cloudera-scm:cloudera-scm /opt/cloudera" 2>/dev/null || true
    log_success "$node: 权限已设置"
    
    echo ""
done

# 验证
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  验证分发结果"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SUCCESS_COUNT=0
for node in "${NODES[@]}"; do
    if ssh $node "test -f /opt/cloudera/parcel-cache/$(basename $PARCEL_FILE)" 2>/dev/null; then
        SIZE=$(ssh $node "du -h /opt/cloudera/parcel-cache/$(basename $PARCEL_FILE) | awk '{print \$1}'" 2>/dev/null)
        log_success "$node: Parcel 存在 ($SIZE)"
        ((SUCCESS_COUNT++))
    else
        log_error "$node: Parcel 不存在"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  分发完成汇总"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "成功分发: $SUCCESS_COUNT/${#NODES[@]} 个节点"
echo ""

if [ $SUCCESS_COUNT -eq ${#NODES[@]} ]; then
    log_success "所有节点分发成功！"
    echo ""
    echo "📋 后续步骤："
    echo "  1. 在 CM 界面刷新 Parcels 页面"
    echo "  2. CDH Parcel 应该显示为 'Downloaded'"
    echo "  3. 点击 'Distribute' 按钮"
    echo "  4. 等待分发完成后点击 'Activate'"
    echo ""
    echo "🌐 访问 CM:"
    echo "  http://node01:7180"
    echo "  或"
    echo "  http://192.168.56.151:7180"
else
    log_warning "部分节点分发失败，请检查日志"
fi

echo ""
