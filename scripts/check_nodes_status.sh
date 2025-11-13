#!/bin/bash
# 检查集群节点状态
# author: RaynLiu

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

NODES=("node01" "node02" "node03")

echo "========================================"
echo "  集群节点状态检查"
echo "========================================"
echo ""

for node in "${NODES[@]}"; do
    echo -n "检查 $node ... "
    
    # 检查 ping
    if ping -c 1 -W 2 $node &>/dev/null; then
        echo -e "${GREEN}在线${NC}"
        
        # 检查 SSH
        if timeout 5 ssh -o ConnectTimeout=3 -o BatchMode=yes $node "echo 'SSH OK'" &>/dev/null; then
            echo "  └─ SSH: ${GREEN}✓ 可连接${NC}"
            
            # 检查磁盘空间
            disk_info=$(ssh $node "df -h / | tail -1 | awk '{print \$2, \$3, \$4, \$5}'")
            echo "  └─ 磁盘: $disk_info"
        else
            echo "  └─ SSH: ${RED}✗ 无法连接（可能正在重启）${NC}"
        fi
    else
        echo -e "${RED}离线${NC}"
    fi
    echo ""
done

echo "========================================"
echo "  检查完成"
echo "========================================"
