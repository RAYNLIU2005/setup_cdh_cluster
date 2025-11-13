#!/bin/bash
# 在所有节点上执行磁盘扩容
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================"
echo "  集群磁盘扩容 - 批量执行脚本"
echo "========================================"
echo ""

NODES=("node02" "node03")

# 复制扩容脚本到其他节点
echo -e "${BLUE}步骤 1: 复制扩容脚本到其他节点...${NC}"
for node in "${NODES[@]}"; do
    echo "  复制到 $node..."
    scp /root/setup_cdh_cluster/scripts/expand_partition_fdisk.sh $node:/root/
done
echo -e "${GREEN}✓ 脚本复制完成${NC}"
echo ""

# 在每个节点上执行扩容
for node in "${NODES[@]}"; do
    echo "========================================"
    echo -e "${BLUE}处理节点: $node${NC}"
    echo "========================================"
    echo ""
    
    echo -e "${YELLOW}请在 $node 上手动执行以下命令:${NC}"
    echo ""
    echo "  ssh $node"
    echo "  chmod +x /root/expand_partition_fdisk.sh"
    echo "  /root/expand_partition_fdisk.sh"
    echo "  # 输入: YES"
    echo "  # 重启后执行:"
    echo "  pvresize /dev/sda2 && lvextend -l +100%FREE /dev/centos/root && xfs_growfs / && df -h /"
    echo ""
    read -p "按 Enter 继续处理下一个节点..."
    echo ""
done

echo "========================================"
echo -e "${GREEN}所有节点扩容脚本已准备就绪！${NC}"
echo "========================================"
echo ""
echo "手动执行步骤："
echo "1. ssh node02 && /root/expand_partition_fdisk.sh"
echo "2. 重启 node02"
echo "3. ssh node02 && pvresize /dev/sda2 && lvextend -l +100%FREE /dev/centos/root && xfs_growfs /"
echo "4. 对 node03 重复步骤 1-3"
echo ""
