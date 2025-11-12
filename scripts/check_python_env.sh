#!/bin/bash
# ==========================================
# Python 环境检查脚本
# Copyright © 2025 RaynLiu
# 保留所有权利 All Rights Reserved
# ==========================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "=========================================="
echo "  Python 环境检查"
echo "  Copyright © 2025 RaynLiu"
echo "=========================================="
echo ""

# 检查 Python 2
echo -e "${BLUE}检查 Python 2:${NC}"
if command -v python2 &>/dev/null; then
    PYTHON2_VERSION=$(python2 --version 2>&1)
    echo -e "${GREEN}✓${NC} Python 2 已安装: $PYTHON2_VERSION"
else
    echo -e "${YELLOW}⚠${NC} Python 2 未安装"
fi
echo ""

# 检查 Python 3
echo -e "${BLUE}检查 Python 3:${NC}"
if command -v python3 &>/dev/null; then
    PYTHON3_VERSION=$(python3 --version)
    echo -e "${GREEN}✓${NC} Python 3 已安装: $PYTHON3_VERSION"
    
    # 检查版本号
    PY_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)")
    PY_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
    
    if [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -ge 8 ]; then
        echo -e "${GREEN}✓${NC} Python 版本符合要求 (>= 3.8)"
    elif [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -ge 6 ]; then
        echo -e "${YELLOW}⚠${NC} Python 版本可用但建议升级到 3.8+ (当前: 3.$PY_MINOR)"
    else
        echo -e "${RED}✗${NC} Python 版本过低，需要 >= 3.6"
    fi
else
    echo -e "${RED}✗${NC} Python 3 未安装"
    echo ""
    echo "安装命令："
    echo "  yum install -y python3"
    exit 1
fi
echo ""

# 检查 pip3
echo -e "${BLUE}检查 pip3:${NC}"
if command -v pip3 &>/dev/null; then
    PIP3_VERSION=$(pip3 --version)
    echo -e "${GREEN}✓${NC} pip3 已安装: $PIP3_VERSION"
else
    echo -e "${RED}✗${NC} pip3 未安装"
    echo ""
    echo "安装命令："
    echo "  yum install -y python3-pip"
    exit 1
fi
echo ""

# 检查 Python 开发包
echo -e "${BLUE}检查 Python 开发包:${NC}"
if rpm -qa | grep -q python3-devel; then
    echo -e "${GREEN}✓${NC} python3-devel 已安装"
else
    echo -e "${YELLOW}⚠${NC} python3-devel 未安装（部分包编译需要）"
    echo "  安装: yum install -y python3-devel"
fi
echo ""

# 检查必要的 Python 包
echo -e "${BLUE}检查 Python 依赖包:${NC}"

# PyMySQL
if python3 -c "import pymysql" 2>/dev/null; then
    PYMYSQL_VERSION=$(python3 -c "import pymysql; print(pymysql.__version__)" 2>/dev/null)
    echo -e "${GREEN}✓${NC} PyMySQL 已安装: $PYMYSQL_VERSION"
else
    echo -e "${YELLOW}⚠${NC} PyMySQL 未安装（部署时会自动安装）"
    echo "  手动安装: pip3 install pymysql"
fi

# Ansible Python 支持
if python3 -c "import ansible" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Ansible Python 模块已安装"
else
    echo -e "${YELLOW}⚠${NC} Ansible Python 模块未安装（通常不需要单独安装）"
fi
echo ""

# 检查 Python 路径
echo -e "${BLUE}Python 可执行文件位置:${NC}"
echo "  python3: $(which python3 2>/dev/null || echo '未找到')"
echo "  pip3: $(which pip3 2>/dev/null || echo '未找到')"
echo ""

# 检查软链接
echo -e "${BLUE}检查兼容性软链接:${NC}"
if [ -L /usr/local/bin/python ] && [ "$(readlink /usr/local/bin/python)" = "/usr/bin/python3" ]; then
    echo -e "${GREEN}✓${NC} python -> python3 软链接已创建"
else
    echo -e "${YELLOW}⚠${NC} python -> python3 软链接未创建（部署时会自动创建）"
fi

if [ -L /usr/local/bin/pip ] && [ "$(readlink /usr/local/bin/pip)" = "/usr/bin/pip3" ]; then
    echo -e "${GREEN}✓${NC} pip -> pip3 软链接已创建"
else
    echo -e "${YELLOW}⚠${NC} pip -> pip3 软链接未创建（部署时会自动创建）"
fi
echo ""

# 显示 Python 系统信息
echo -e "${BLUE}Python 系统信息:${NC}"
python3 << 'EOF'
import sys
print(f"  版本: {sys.version}")
print(f"  路径: {sys.executable}")
print(f"  平台: {sys.platform}")
print(f"  编码: {sys.getdefaultencoding()}")
EOF
echo ""

# 检查 pip 镜像源配置
echo -e "${BLUE}检查 pip 镜像源:${NC}"
if [ -f ~/.pip/pip.conf ]; then
    echo -e "${GREEN}✓${NC} pip 配置文件存在"
    if grep -q "aliyun" ~/.pip/pip.conf 2>/dev/null; then
        echo -e "${GREEN}✓${NC} 已配置国内镜像源"
    fi
else
    echo -e "${YELLOW}⚠${NC} pip 配置文件不存在（建议配置国内镜像加速）"
fi
echo ""

# 总结
echo "=========================================="
echo -e "${GREEN}Python 环境检查完成！${NC}"
echo "=========================================="
echo ""

# 判断是否需要安装
if ! command -v python3 &>/dev/null || ! command -v pip3 &>/dev/null; then
    echo -e "${RED}需要先安装 Python 3 环境${NC}"
    echo ""
    echo "快速安装命令："
    echo "  yum install -y python3 python3-pip python3-devel"
    echo ""
    exit 1
else
    echo -e "${GREEN}Python 环境已就绪！${NC}"
    echo ""
    echo "如果需要手动安装依赖："
    echo "  pip3 install pymysql -i https://mirrors.aliyun.com/pypi/simple/"
    echo ""
    echo "或者直接运行部署（会自动安装）："
    echo "  cd /root/setup_cdh_cluster"
    echo "  make deploy"
    echo ""
fi
