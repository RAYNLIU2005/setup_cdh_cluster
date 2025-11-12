#!/bin/bash
# 修复所有脚本执行权限
# Copyright © 2025 RaynLiu

PROJECT_DIR="/root/setup_cdh_cluster"

echo "=========================================="
echo "  修复脚本执行权限"
echo "=========================================="
echo ""

cd "$PROJECT_DIR/scripts" || exit 1

# 给所有 .sh 文件添加执行权限
for script in *.sh; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo "✓ $script"
    fi
done

echo ""
echo "=========================================="
echo "  ✓ 所有脚本权限已修复"
echo "=========================================="
