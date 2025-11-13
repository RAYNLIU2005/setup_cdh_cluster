#!/bin/bash
# 使用 fdisk 手动扩展分区脚本
# author: RaynLiu
# 适用于 growpart 失败的情况

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================"
echo "  使用 fdisk 扩展分区脚本"
echo "========================================"
echo ""

# 显示当前分区信息
echo -e "${BLUE}当前分区信息：${NC}"
fdisk -l /dev/sda | grep -E "Disk /dev/sda|/dev/sda"
echo ""

# 获取 sda2 的起始扇区
START_SECTOR=$(fdisk -l /dev/sda | grep /dev/sda2 | awk '{print $2}')
echo -e "${YELLOW}检测到 /dev/sda2 起始扇区: $START_SECTOR${NC}"
echo ""

if [ -z "$START_SECTOR" ]; then
    echo -e "${RED}错误：无法检测到 /dev/sda2${NC}"
    exit 1
fi

# 确认操作
echo -e "${RED}警告：此操作将删除并重建 /dev/sda2 分区！${NC}"
echo -e "${YELLOW}数据不会丢失，但请确保已备份重要数据！${NC}"
echo ""
read -p "确认继续？(输入 YES 继续): " confirm

if [ "$confirm" != "YES" ]; then
    echo "操作已取消"
    exit 0
fi

# 备份分区表
echo ""
echo -e "${BLUE}备份分区表...${NC}"
fdisk -l /dev/sda > /root/partition_backup_$(date +%Y%m%d_%H%M%S).txt
echo -e "${GREEN}✓ 分区表已备份到 /root/partition_backup_*.txt${NC}"

# 使用 fdisk 重建分区
echo ""
echo -e "${BLUE}重建分区...${NC}"
echo -e "d\n2\nn\np\n2\n$START_SECTOR\n\nt\n2\n8e\nw" | fdisk /dev/sda

echo ""
echo -e "${GREEN}✓ 分区重建完成${NC}"
echo ""
echo -e "${YELLOW}========================================"
echo "  需要重启系统以应用更改"
echo "========================================${NC}"
echo ""
echo "重启后执行以下命令完成扩容："
echo ""
echo "  pvresize /dev/sda2"
echo "  lvextend -l +100%FREE /dev/centos/root"
echo "  xfs_growfs /"
echo "  df -h"
echo ""
read -p "现在重启系统？(yes/no): " reboot_now

if [ "$reboot_now" = "yes" ]; then
    echo "正在重启..."
    reboot
else
    echo "请手动重启系统后执行扩容命令"
fi
