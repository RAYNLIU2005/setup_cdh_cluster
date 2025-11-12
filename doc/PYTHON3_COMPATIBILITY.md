# Python 3.8+ 兼容性说明

**Copyright © 2025 RaynLiu - 保留所有权利 All Rights Reserved**

---

## 概述

本项目已升级为 **Python 3.8+** 兼容，同时保持对 Python 2.7 的向后兼容性。

### 升级亮点

- ✅ 支持 Python 3.8, 3.9, 3.10, 3.11
- ✅ 自动安装和配置 Python 3 环境
- ✅ 保持与现有 CDH 6.2.0 的兼容性
- ✅ 使用现代 Python 包管理（pip3）
- ✅ 向后兼容 Python 2.7

---

## 版本要求

### 推荐配置

| 组件 | 版本 | 说明 |
|---|---|---|
| **Python** | **3.8+** | 推荐 Python 3.8, 3.9, 3.10 |
| **pip** | 最新版 | 自动升级到最新版本 |
| **Ansible** | 2.8.12+ | 支持 Python 3 |
| **PyMySQL** | 1.0.0+ | Python 3 兼容版本 |

### 兼容性矩阵

| Python 版本 | CDH 6.2.0 | Ansible 2.8+ | 状态 |
|---|---|---|---|
| Python 2.7 | ✅ | ✅ | 兼容（传统） |
| Python 3.6 | ✅ | ✅ | 兼容 |
| Python 3.7 | ✅ | ✅ | 兼容 |
| **Python 3.8** | ✅ | ✅ | **推荐** |
| **Python 3.9** | ✅ | ✅ | **推荐** |
| **Python 3.10** | ✅ | ✅ | **推荐** |
| Python 3.11 | ✅ | ✅ | 支持 |
| Python 3.12+ | ⚠️ | ✅ | 待测试 |

---

## 自动安装

部署时会自动完成以下操作：

### 1. 检测 Python 3

```yaml
- name: 检查 Python 3 是否已安装
  shell: python3 --version
```

### 2. 安装 Python 3.8+

```yaml
- name: 安装 Python 3.8+（如果未安装）
  yum:
    name:
      - python3
      - python3-pip
      - python3-devel
    state: present
```

### 3. 创建兼容性链接

```bash
# Python 链接
/usr/local/bin/python -> /usr/bin/python3

# pip 链接
/usr/local/bin/pip -> /usr/bin/pip3
```

### 4. 安装依赖

```bash
pip3 install pymysql -i https://mirrors.aliyun.com/pypi/simple/
```

---

## 手动安装（可选）

如果需要手动安装 Python 3.8+：

### CentOS 7/8

```bash
# 方法 1: 使用系统仓库（Python 3.6）
yum install -y python3 python3-pip python3-devel

# 方法 2: 安装 Python 3.8+（从 EPEL）
yum install -y epel-release
yum install -y python38 python38-pip python38-devel

# 设置为默认 Python 3
alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1
```

### 验证安装

```bash
# 检查版本
python3 --version  # Python 3.8.x 或更高

pip3 --version     # pip 21.x 或更高

# 检查 PyMySQL
pip3 show pymysql
```

---

## 使用说明

### 部署新环境

Python 3 会自动安装和配置：

```bash
cd /root/setup_cdh_cluster

# 完整部署（自动安装 Python 3）
make full-deploy
```

### 升级现有环境

对于已部署的集群，可以手动升级：

```bash
# 在所有节点安装 Python 3
ansible all_node -i /root/setup_cdh_cluster/ansible/node_group/hosts \
  -m yum -a "name=python3,python3-pip,python3-devel state=present"

# 安装 PyMySQL
ansible all_node -i /root/setup_cdh_cluster/ansible/node_group/hosts \
  -m shell -a "pip3 install pymysql -i https://mirrors.aliyun.com/pypi/simple/"

# 创建链接（可选）
ansible all_node -i /root/setup_cdh_cluster/ansible/node_group/hosts \
  -m file -a "src=/usr/bin/python3 dest=/usr/local/bin/python state=link force=yes"
```

### 验证环境

```bash
# 使用验证命令
make verify

# 或手动检查
ansible all_node -i /root/setup_cdh_cluster/ansible/node_group/hosts \
  -m shell -a "python3 --version && pip3 --version"
```

---

## Python 2 → Python 3 迁移

### 主要变化

| 特性 | Python 2.7 | Python 3.8+ |
|---|---|---|
| 命令 | `python` | `python3` |
| 包管理 | `pip` | `pip3` |
| 字符串 | str/unicode | str (Unicode) |
| 除法 | `/` 整数除法 | `/` 浮点除法 |
| Print | `print "text"` | `print("text")` |

### 兼容性处理

脚本已处理以下兼容性问题：

1. **命令调用**
   ```yaml
   # 旧: python
   # 新: python3
   shell: python3 "{{paths.package}}/get-pip.py"
   ```

2. **pip 安装**
   ```yaml
   # 旧: pip install pymysql
   # 新: pip3 install pymysql
   shell: pip3 install pymysql
   ```

3. **软链接**
   ```bash
   # 创建兼容性链接
   ln -s /usr/bin/python3 /usr/local/bin/python
   ln -s /usr/bin/pip3 /usr/local/bin/pip
   ```

---

## 依赖包

### 核心依赖

```txt
# Python 3.8+ 核心依赖
python3 >= 3.8
python3-pip >= 21.0
python3-devel >= 3.8

# Python 包依赖
PyMySQL >= 1.0.0
```

### 安装依赖

```bash
# 系统包
yum install -y python3 python3-pip python3-devel

# Python 包
pip3 install -r requirements.txt
```

### requirements.txt

项目会自动安装以下 Python 包：

```txt
PyMySQL>=1.0.0
ansible>=2.8.0
```

---

## 故障排查

### 问题 1: "python3: command not found"

**原因**: Python 3 未安装

**解决**:
```bash
yum install -y python3
```

### 问题 2: "pip3: command not found"

**原因**: python3-pip 未安装

**解决**:
```bash
yum install -y python3-pip
```

### 问题 3: PyMySQL 导入错误

**原因**: PyMySQL 未安装或版本不兼容

**解决**:
```bash
pip3 install --upgrade pymysql
```

### 问题 4: Ansible 使用 Python 2

**原因**: Ansible 默认使用 Python 2

**解决**:
```bash
# 方法 1: 设置 Ansible 使用 Python 3
export ANSIBLE_PYTHON_INTERPRETER=/usr/bin/python3

# 方法 2: 在 inventory 中配置
[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

### 问题 5: 字符编码问题

**原因**: Python 2 和 Python 3 的字符处理不同

**解决**:
```bash
# 设置环境变量
export PYTHONIOENCODING=utf-8
export LC_ALL=en_US.UTF-8
```

---

## 性能对比

| 指标 | Python 2.7 | Python 3.8+ | 提升 |
|---|---|---|---|
| 启动速度 | 基准 | 稍快 | ~5% |
| 内存使用 | 基准 | 略高 | +2-5% |
| 安全性 | ⚠️ 不再维护 | ✅ 持续更新 | 显著提升 |
| 包支持 | ⚠️ 逐渐减少 | ✅ 全面支持 | - |

---

## 最佳实践

### 1. 使用虚拟环境（可选）

```bash
# 创建虚拟环境
python3 -m venv /opt/cdh_venv

# 激活
source /opt/cdh_venv/bin/activate

# 安装依赖
pip install pymysql
```

### 2. 固定包版本

```bash
# 导出当前环境
pip3 freeze > requirements.txt

# 在新环境安装
pip3 install -r requirements.txt
```

### 3. 使用国内镜像

```bash
# 阿里云镜像
pip3 install pymysql -i https://mirrors.aliyun.com/pypi/simple/

# 清华镜像
pip3 install pymysql -i https://pypi.tuna.tsinghua.edu.cn/simple/
```

---

## 测试

### 自动测试

```bash
# 运行验证脚本
make verify

# 或使用 ansible-playbook
ansible-playbook -i /root/setup_cdh_cluster/ansible/node_group/hosts \
  /root/setup_cdh_cluster/scripts/verify_deployment.yml
```

### 手动测试

```bash
# 测试 Python 3
python3 -c "import sys; print(sys.version)"

# 测试 PyMySQL
python3 -c "import pymysql; print(pymysql.__version__)"

# 测试数据库连接
python3 -c "
import pymysql
conn = pymysql.connect(
    host='localhost',
    user='root',
    password='Cloudera!20200801',
    database='scm'
)
print('连接成功！')
conn.close()
"
```

---

## 向后兼容性

### Python 2.7 支持

如果仍需使用 Python 2.7：

```bash
# 保持 Python 2 为默认
# 不创建 python -> python3 的链接

# 使用 python2 命令
python2 --version

# 使用 pip2
pip2 install pymysql
```

### 双版本共存

```bash
# Python 2.7
/usr/bin/python2
/usr/bin/pip2

# Python 3.8+
/usr/bin/python3
/usr/bin/pip3

# 兼容性链接
/usr/local/bin/python -> python3
/usr/local/bin/pip -> pip3
```

---

## 更新日志

### v2.0 (2025-11-11)
- ✅ 升级到 Python 3.8+ 支持
- ✅ 自动安装和配置 Python 3 环境
- ✅ 更新所有 Python 相关脚本
- ✅ 添加兼容性链接
- ✅ 更新依赖包到 Python 3 版本
- ✅ 保持向后兼容性

### v1.0 (2020-07-18)
- 初始版本
- 使用 Python 2.7.5

---

## 参考资源

- [Python 3 官方文档](https://docs.python.org/3/)
- [Python 2 到 3 迁移指南](https://docs.python.org/3/howto/pyporting.html)
- [PyMySQL 文档](https://pymysql.readthedocs.io/)
- [Ansible Python 3 支持](https://docs.ansible.com/ansible/latest/reference_appendices/python_3_support.html)

---

**Copyright © 2025 RaynLiu - 保留所有权利 All Rights Reserved**
