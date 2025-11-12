#!/bin/bash
# SSH 免密登录测试脚本
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SSH 免密登录状态测试"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

all_ok=true

for node in node01 node02 node03; do
    # 测试网络连通性
    if ping -c 1 -W 2 "$node" &>/dev/null; then
        # 测试SSH免密
        if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$node" "exit" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $node - SSH 免密已配置"
        else
            echo -e "  ${RED}✗${NC} $node - 需要密码"
            all_ok=false
        fi
    else
        echo -e "  ${RED}✗${NC} $node - 网络不通"
        all_ok=false
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$all_ok" = true ]; then
    echo -e "${GREEN}✓ 所有节点 SSH 免密登录正常${NC}"
    echo ""
    exit 0
else
    echo -e "${YELLOW}⚠ 部分节点需要配置${NC}"
    echo ""
    echo "配置方法："
    echo "  make setup-ssh"
    echo ""
    exit 1
fi
