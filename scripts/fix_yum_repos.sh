#!/bin/bash
# 修复 YUM 源配置脚本
# Copyright © 2025 RaynLiu

if [ ! -f /etc/yum.repos.d/CentOS-Base.repo ]; then
    echo "配置阿里云镜像源..."
    cat > /etc/yum.repos.d/CentOS-Base.repo << 'EOF'
[base]
name=CentOS-7 - Base
baseurl=https://mirrors.aliyun.com/centos/7/os/$basearch/
gpgcheck=0
enabled=1

[updates]
name=CentOS-7 - Updates
baseurl=https://mirrors.aliyun.com/centos/7/updates/$basearch/
gpgcheck=0
enabled=1

[extras]
name=CentOS-7 - Extras
baseurl=https://mirrors.aliyun.com/centos/7/extras/$basearch/
gpgcheck=0
enabled=1
EOF
fi

if [ ! -f /etc/yum.repos.d/epel.repo ]; then
    echo "配置 EPEL 源..."
    cat > /etc/yum.repos.d/epel.repo << 'EOF'
[epel]
name=EPEL for CentOS 7
baseurl=https://mirrors.aliyun.com/epel/7/$basearch
gpgcheck=0
enabled=1
EOF
fi
