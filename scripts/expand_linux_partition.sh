#!/bin/bash
# Linux 分区和文件系统扩容脚本
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# 用于 VirtualBox 虚拟磁盘扩容后的分区扩展

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "========================================"
echo "  Linux 磁盘分区扩容脚本"
echo "  适用于 VirtualBox 虚拟机 LVM 扩容"
echo "========================================"
echo ""

# 显示当前状态
echo -e "${BLUE}[步骤 0/6]${NC} 当前磁盘状态："
echo ""
lsblk
echo ""
df -h /
echo ""

# 确认操作
read -p "$(echo -e ${YELLOW}确认要扩展磁盘分区吗? \(yes/no\): ${NC})" confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${RED}操作已取消${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}[步骤 1/6]${NC} 安装必要工具..."
yum install -y cloud-utils-growpart >/dev/null 2>&1 && echo -e "${GREEN}✓ cloud-utils-growpart 已安装${NC}" || echo -e "${YELLOW}⚠ 工具已存在${NC}"

echo ""
echo -e "${BLUE}[步骤 2/6]${NC} 扩展物理分区 /dev/sda2..."
if growpart /dev/sda 2; then
    echo -e "${GREEN}✓ 分区扩展成功${NC}"
else
    echo -e "${YELLOW}⚠ 分区可能已经是最大，或需要重启${NC}"
fi

echo ""
echo -e "${BLUE}[步骤 3/6]${NC} 更新内核分区表..."
partprobe /dev/sda
sleep 2
echo -e "${GREEN}✓ 分区表已更新${NC}"

echo ""
echo -e "${BLUE}[步骤 4/6]${NC} 扩展物理卷 (PV)..."
if pvresize /dev/sda2; then
    echo -e "${GREEN}✓ 物理卷扩展成功${NC}"
else
    echo -e "${RED}✗ 物理卷扩展失败${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[步骤 5/6]${NC} 扩展逻辑卷 (LV)..."
if lvextend -l +100%FREE /dev/centos/root; then
    echo -e "${GREEN}✓ 逻辑卷扩展成功${NC}"
else
    echo -e "${YELLOW}⚠ 逻辑卷可能已经是最大${NC}"
fi

echo ""
echo -e "${BLUE}[步骤 6/6]${NC} 扩展文件系统..."
# 检测文件系统类型
FS_TYPE=$(df -T / | tail -1 | awk '{print $2}')
echo "  文件系统类型: $FS_TYPE"

if [ "$FS_TYPE" = "xfs" ]; then
    if xfs_growfs /; then
        echo -e "${GREEN}✓ XFS 文件系统扩展成功${NC}"
    else
        echo -e "${RED}✗ 文件系统扩展失败${NC}"
        exit 1
    fi
elif [ "$FS_TYPE" = "ext4" ]; then
    if resize2fs /dev/centos/root; then
        echo -e "${GREEN}✓ EXT4 文件系统扩展成功${NC}"
    else
        echo -e "${RED}✗ 文件系统扩展失败${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ 未知文件系统类型: $FS_TYPE${NC}"
    exit 1
fi

# 显示结果
echo ""
echo "========================================"
echo -e "  ${GREEN}扩容完成！${NC}"
echo "========================================"
echo ""
echo "新的磁盘状态："
echo ""
df -h /
echo ""
lsblk /dev/sda
echo ""
echo -e "${GREEN}根分区已成功扩展到最大可用空间！${NC}"
echo ""
