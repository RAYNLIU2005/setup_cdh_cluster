# CDH 集群自动化部署系统

[![Version](https://img.shields.io/badge/version-2.2-blue.svg)](https://github.com/RaynLiu/setup_cdh_cluster)
[![CDH](https://img.shields.io/badge/CDH-6.2.0-orange.svg)](https://www.cloudera.com/)
[![Python](https://img.shields.io/badge/python-3.8+-green.svg)](https://www.python.org/)
[![Ansible](https://img.shields.io/badge/ansible-2.8+-red.svg)](https://www.ansible.com/)
[![License](https://img.shields.io/badge/license-All%20Rights%20Reserved-lightgrey.svg)](LICENSE)
[![Inspired by](https://img.shields.io/badge/inspired%20by-playground-brightgreen.svg)](https://gitee.com/several-boats/playground.git)


> 🚀 基于 Ansible 的 CDH 6.2.0 集群自动化部署工具，支持 Python 3.8+，使用软链接优化存储，一键修复常见问题，大幅提升部署效率和稳定性。
> 
> 🎉 **灵感来自 [playground](https://gitee.com/several-boats/playground.git)** - 交互式初始化设计，参考 `playground init` 命令实现 `make init`，一键完成环境配置。

## 🌟 亮点功能

- 🎯 **一键修复** - `make fix-all` 自动修复所有已知问题
- 🚀 **智能启停** - 自动验证配置，智能等待服务启动
- 📦 **可靠分发** - 支持 HTTP 和手动 Parcel 分发
- ✅ **稳定可靠** - 修复了 Agent 配置、BitTorrent 等常见问题
- 🎨 **优雅体验** - 交互式初始化，美化的输出界面
- 🔑 **SSH 免密登录** - 灵感来自 playground，使用 expect 自动化（必看！）
- 📚 **完善文档** - 详细的使用和故障排查文档

> 📖 **新手入门？** 查看 [⚡ 10分钟快速开始指南](QUICK_START.md)

## 📑 目录

- [⚠️ 使用前提条件（必读）](#️-使用前提条件必读)
  - [🖥️ 虚拟机要求](#️-虚拟机要求)
  - [📦 安装包准备](#-安装包准备)
- [🚀 快速开始流程](#-快速开始流程)
- [📋 集群节点信息](#-集群节点信息)
- [🔧 环境准备（手动配置）](#-环境准备手动配置)
- [🌐 访问 Cloudera Manager Web 界面](#-访问-cloudera-manager-web-界面)
- [🛠️ 常见问题一键修复（v2.2 新增）](#️-常见问题一键修复v22-新增)
- [🔧 修复工具汇总（v2.2）](#-修复工具汇总v22)
- [📚 文档中心](#-文档中心)
- [❓ FAQ](#-faq)

---

## ⚠️ 使用前提条件（必读）

### 🖥️ 虚拟机要求

本项目需要使用**预配置的虚拟机环境**，请通过以下方式获取：

**百度网盘下载地址：**
```
链接: https://pan.baidu.com/s/1SJUKskiSnO4sIIKNg0Ujjw?pwd=4fds
提取码: 4fds
```

**虚拟机配置说明：**

| 节点 | IP地址 | 主机名 | 角色 | 推荐配置 |
|------|--------|--------|------|----------|
| node01 | 192.168.56.151 | node01 | Master | 4核CPU + 4GB内存 |
| node02 | 192.168.56.152 | node02 | Worker | 4核CPU + 4GB内存 |
| node03 | 192.168.56.153 | node03 | Worker | 4核CPU + 4GB内存 |

**⚡ 配置建议：**
- ✅ **推荐配置**：4核CPU + 4GB内存（运行流畅）
- ⚠️ **最低配置**：2核CPU + 2GB内存（可能卡顿）
- 💾 **磁盘空间**：建议每个节点至少 40GB

### 📦 安装包准备

下载虚拟机后，需要准备 CDH 安装包：

**百度网盘下载地址（总大小 4.49 GB）：**
```
链接: https://pan.baidu.com/s/1nbhiVhN0GWYUo9JmHgC4Pg
提取码: ax3w
```

**下载内容说明：**
- 📦 `packages.tar.gz` - CDH 组件包（RPM、JDK、MySQL 等）
- 📦 `parcels.tar.gz` - CDH Parcel 文件

#### 📝 详细安装步骤

**1. 创建目录**
```bash
# 在 node01 节点上执行（仅主节点）
mkdir -p /opt/base_file
cd /opt/base_file
```

**2. 上传压缩包**
```bash
# 使用 WinSCP 或 rz 命令上传两个压缩包到 /opt/base_file
# - packages.tar.gz
# - parcels.tar.gz

# 或使用 rz 命令（需要安装 lrzsz）
yum install -y lrzsz
cd /opt/base_file
rz  # 选择 packages.tar.gz
rz  # 选择 parcels.tar.gz
```

**3. 解压压缩包**
```bash
cd /opt/base_file

# 解压 packages
tar -xzf packages.tar.gz

# 解压 parcels
tar -xzf parcels.tar.gz

# 删除压缩包释放空间（可选）
rm -f packages.tar.gz parcels.tar.gz
```

**4. 验证目录结构**
```bash
# 确认目录结构
tree -L 2 /opt/base_file/
# 或
ls -lh /opt/base_file/

# 应该看到：
# /opt/base_file/
# ├── packages/  - CDH 组件包（23 个文件）
# │   ├── cloudera-manager-*.rpm
# │   ├── jdk-8u261-linux-x64.tar.gz
# │   ├── mysql-*.rpm
# │   └── ...
# └── parcels/   - CDH Parcel 文件（2 个文件）
#     ├── CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel
#     └── CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel.sha
```

**5. 验证文件完整性**
```bash
# 检查 packages 目录
ls -lh /opt/base_file/packages/ | wc -l
# 应该有 23 个文件

# 检查关键文件
ls /opt/base_file/packages/ | grep -E "(jdk|mysql|cloudera)"

# 检查 parcels 目录
ls -lh /opt/base_file/parcels/
# 应该有 CDH parcel 和 sha 文件
```

---

## 特性

### 部署特性
- ✅ **Python 3.8+ 支持** - 现代 Python 环境，向后兼容 Python 2.7
- ✅ **存储优化** - 使用软链接替代复制，节省 6-8GB 磁盘空间
- ✅ **开机自启动** - 服务自动配置开机启动
- ✅ **容错机制** - YUM 源智能容错，部署成功率高
- ✅ **一键部署** - 简单命令完成全部配置
- ✅ **服务依赖管理** - 自动检查服务启动顺序，避免连接错误
- ✅ **健康检查** - 全面的服务状态检查和诊断工具
- ✅ **故障自动修复** - 常见问题一键修复脚本

### 工程化特性（v2.1 新增）
- ✅ **依赖管理** - requirements.txt 标准化依赖管理
- ✅ **环境配置** - .env 文件支持，环境分离
- ✅ **Docker支持** - 完整的容器化部署方案
- ✅ **自动化测试** - 完整的测试框架和测试用例
- ✅ **统一日志** - 结构化日志系统，彩色输出
- ✅ **配置管理** - 集中化配置管理模块
- ✅ **代码质量** - 高内聚低耦合，模块化设计

## 版本要求

| 组件 | 版本 | 说明 |
|---|---|---|
| CDH | 6.2.0 | Hadoop 生态系统 |
| Ansible | 2.8.12+ | 自动化部署工具 |
| **Python** | **3.8+** | 推荐 Python 3.8, 3.9, 3.10 |
| CentOS | 7.x | 操作系统 | 


## 🚀 快速开始流程

### 📍 整体流程图

```
1. 下载虚拟机 (百度网盘) + 下载安装包
   ↓
2. 配置虚拟机 (4核 + 4GB 推荐)
   ↓
3. 启动三个节点 (node01, node02, node03)
   ↓
4. 准备安装包 (/opt/base_file + 解压)
   ↓
5. 克隆项目 (git clone 或上传)
   ↓
6. 交互式初始化 (make init) ⭐ 推荐
   ↓
7. 一键部署 (make deploy)
   ↓
8. 访问 CM 界面 (http://192.168.56.151:7180)
```

### 📝 详细步骤

#### 步骤 1: 下载准备

```bash
# 下载内容：
# 1. 虚拟机镜像（百度网盘：https://pan.baidu.com/s/1SJUKskiSnO4sIIKNg0Ujjw?pwd=4fds）
# 2. CDH 安装包（百度网盘：https://pan.baidu.com/s/1nbhiVhN0GWYUo9JmHgC4Pg 密码: ax3w）
```

#### 步骤 2-3: 启动虚拟机

```bash
# 1. 导入虚拟机到 VirtualBox/VMware
# 2. 配置网络：Host-Only 模式
# 3. 启动 node01, node02, node03
# 4. 默认密码：root/123456
```

#### 步骤 4: 准备安装包

```bash
# 在 node01 节点上执行
mkdir -p /opt/base_file
cd /opt/base_file

# 上传 packages.tar.gz 和 parcels.tar.gz
# 使用 WinSCP 或 rz 命令

# 解压
tar -xzf packages.tar.gz
tar -xzf parcels.tar.gz
rm -f *.tar.gz  # 释放空间

# 验证
ls -lh /opt/base_file/
# 应该有 packages/ 和 parcels/ 两个目录
```

#### 步骤 5: 克隆项目

```bash
# 方法 1：使用 git 克隆（推荐）
cd /root
git clone https://gitee.com/your-repo/setup_cdh_cluster.git
cd setup_cdh_cluster

# 方法 2：直接上传项目文件
mkdir -p /root/setup_cdh_cluster
# 使用 WinSCP 上传项目文件到 /root/setup_cdh_cluster
```

#### 步骤 6: 交互式初始化 ⭐ 灵感来自 playground

> 🎉 **新功能！**完全参考 [playground](https://gitee.com/several-boats/playground.git) 项目设计，特别是 **SSH 免密登录使用 playground 的 expect 自动化方案**

> ⚠️ **重要**: SSH 免密登录功能完全借鉴 playground 项目的 `sshFreeLogin.sh` 实现，使用 expect 工具自动化处理密码输入

```bash
cd /root/setup_cdh_cluster

# 一键初始化（完全模仿 playground init）
make init

# 会自动完成：
# 1. 检查集群配置
# 2. 检查安装包目录
# 3. 配置 YUM 源（阿里云镜像）- 参考 playground
# 4. 安装系统依赖（expect, ntpdate, wget, curl 等）- 参考 playground
# 5. 安装 Python 3 和 Ansible
# 6. 🔑 配置 SSH 免密登录（灵感来源: playground/systems/sshFreeLogin.sh）
# 7. 配置系统环境（防火墙、SELinux、Swap、时间同步）- 参考 playground
# 8. 运行环境测试
# 9. 同步到其他节点（node02, node03）- 参考 playground
```

**交互示例：**

```
IP: 192.168.56.151
Hostname: node01
Username: root
Password: 12****56
=======================================
请确认以上信息是否正确 (y/n): y

配置阿里云镜像源
元数据缓存已建立
expect 已安装
ntpdate 已安装
13 Nov 00:14:08 ntpdate: adjust time server
关闭防火墙、SELINUX
SSH 免密登录配置成功

是否将环境配置同步到其他节点? (y/n，默认 y): y

目前正在设置 node02 节点的系统环境
目前正在设置 node03 节点的系统环境

┌────────────────────────┐
│  环境初始化成功！      │
└────────────────────────┘
```

#### 步骤 7: 一键部署

```bash
# 开始部署 CDH 集群
make deploy

# 等待 30-60 分钟，部署会自动完成
```

#### 步骤 8: 访问管理界面

```bash
# 访问 Cloudera Manager
http://192.168.56.151:7180

# 默认账号：
# 用户名: admin
# 密码: admin
```

---

## 🎯 make init vs 手动配置 vs playground

### 📊 对比说明

| 特性 | make init（推荐）| playground init | 手动配置 |
|------|-----------------|----------------|---------|
| 配置方式 | 交互式 + 自动化 | 交互式 + 自动化 | 完全手动 |
| 所需时间 | 5-10 分钟 | 5-10 分钟 | 30-60 分钟 |
| 难度 | ⭐ 简单 | ⭐ 简单 | ⭐⭐⭐⭐ 复杂 |
| YUM 源配置 | ✅ 自动（阿里云） | ✅ 自动（阿里云） | ❌ 需手动 |
| 依赖安装 | ✅ 自动 | ✅ 自动 | ❌ 需手动 |
| SSH 免密 | ✅ expect 自动化 | ✅ expect 自动化 | ❌ 需手动 |
| 系统配置 | ✅ 全自动 | ✅ 全自动 | ❌ 需手动 |
| 集群同步 | ✅ 自动同步 | ✅ 自动同步 | ❌ 需逐个配置 |
| 错误处理 | ✅ 智能诊断 | ⚠️ 基础 | ❌ 自行排查 |
| 适用场景 | CDH 集群部署 | 大数据框架安装 | 学习理解原理 |

### 🌟 make init 的优势

基于 **playground** 项目灵感，结合 CDH 部署特点优化：

1. **🔑 SSH 免密登录（必看！）** - 完全使用 playground 的 expect 自动化方案，灵感来源于 `playground/systems/sshFreeLogin.sh`
2. **智能配置读取** - 从 `.env` 文件读取配置，支持默认值
3. **密码脱敏显示** - 配置展示时自动隐藏敏感信息
4. **详细诊断工具** - YUM、SSH、环境全面诊断
5. **Makefile 集成** - 统一命令入口，易于使用
6. **Ansible 支持** - 后续部署更自动化
7. **完善的日志** - 彩色输出，易于排错
8. **集群节点同步** - 自动同步配置到所有节点（参考 playground）

### 💡 使用建议

- ✅ **推荐**: 使用 `make init`（快速、可靠、易用）
- ⚠️ **可选**: 手动配置（学习理解每一步原理）
- 📚 **参考**: playground 项目（大数据生态工具）

---

## 📋 集群节点信息

| 角色 | IP | hostname | 说明 |
| --- | --- | --- | --- |
| Master  | 192.168.56.151  | node01 | CM Server + NameNode + ResourceManager |
| Worker | 192.168.56.152 | node02 | CM Agent + DataNode + NodeManager |
| Worker | 192.168.56.153 | node03 | CM Agent + DataNode + NodeManager |

---

## 🔧 环境准备（手动配置）

> ⚠️ **注意**: 如果已经使用 `make init`，**无需**再进行手动配置！以下内容仅供学习参考。

自动化部署前，需要完成以下手动配置（仅需一次）

#### 配置 hostname
> 配置各个节点 IP 到 hostname 的映射
```bash
# 编辑 host 文件
vi /etc/hosts

# 添加下列 ip 和 hostname 映射
192.168.56.151  node01
192.168.56.152  node02
192.168.56.153  node03
```

#### 免密登录
> 配置 node01 免密登录到 node01~node03
``` bash
# node01 上安装
yum -y install openssh-clients
# node01 上生成密钥
ssh-keygen -t rsa

# node01 上复制 node01 的~/.ssh/id_rsa.pub 公钥到 node01~node03 的~/.ssh/authorized_keys 中
ssh-copy-id root@node01
ssh-copy-id root@node02
ssh-copy-id root@node03

# 在节点 node01 上测试
# 成功的话应该不用输入任何密码
ssh node02          

```

#### 安装 Ansible 2.8
``` bash
# node01 节点上安装 ansible 2.8
yum install -y centos-release-ansible-28.noarch

# 查看 ansible 版本
ansible --version
```

#### 上传组件安装包
百度云下载链接（总大小 4.49 GB）：[https://pan.baidu.com/s/1nbhiVhN0GWYUo9JmHgC4Pg](https://pan.baidu.com/s/1nbhiVhN0GWYUo9JmHgC4Pg)  密码：ax3w

压缩包内容:

**base_file/packages:**

1. cloudera-manager-agent-6.2.0-968826.el7.x86_64.rpm
2. cloudera-manager-daemons-6.2.0-968826.el7.x86_64.rpm
3. cloudera-manager-server-6.2.0-968826.el7.x86_64.rpm
4. cloudera-manager-server-db-2-6.2.0-968826.el7.x86_64.rpm
5. enterprise-debuginfo-6.3.1-1466458.el7.x86_64.rpm
6. get-pip.py
7. jdk-8u261-linux-x64.tar.gz
8. my.cnf
9. mysql-5.7.30-1.el7.x86_64.rpm-bundle.tar
10. mysql-community-client-5.7.30-1.el7.x86_64.rpm
11. mysql-community-common-5.7.30-1.el7.x86_64.rpm
12. mysql-community-devel-5.7.30-1.el7.x86_64.rpm
13. mysql-community-embedded-5.7.30-1.el7.x86_64.rpm
14. mysql-community-embedded-compat-5.7.30-1.el7.x86_64.rpm
15. mysql-community-embedded-devel-5.7.30-1.el7.x86_64.rpm
16. mysql-community-libs-5.7.30-1.el7.x86_64.rpm
17. mysql-community-libs-compat-5.7.30-1.el7.x86_64.rpm
18. mysql-community-server-5.7.30-1.el7.x86_64.rpm
19. mysql-community-test-5.7.30-1.el7.x86_64.rpm
20. mysql-connector-java-5.1.47.jar
21. mysql_init.sql
22. RPM-GPG-KEY-cloudera
23. scala-2.13.0-M4.tgz

**base_file/parcels:**

1. CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel
2. CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel.sha
3. CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel.sha256
4. KAFKA-4.1.0-1.4.1.0.p0.4-el7.parcel
5. KAFKA-4.1.0-1.4.1.0.p0.4-el7.parcel.sha1
6. manifest.json
7. SPARK2-2.4.0.cloudera1-1.cdh5.13.3.p0.1007356-el7.parcel
8. SPARK2-2.4.0.cloudera1-1.cdh5.13.3.p0.1007356-el7.parcel.sha

```bash
# 解压 zip 包上传组件安装包到 node01，得到两个目录
/opt/base_file/packages
/opt/base_file/parcels
```


#### 组件安装包下载出处
##### 1. JDK

| CDH 版本 | Oracle JDK 支持版本 | OpenJDK 支持版本 |
| --- | --- | --- |
| 5.3 -5.15 | 1.7, 1.8 | none |
| 5.16 and higher 5.x releases | 1.7, 1.8 | 1.8 |
| 6.0 | 1.8 | none |
| 6.1 | 1.8 | 1.8 |
| 6.2 | 1.8 | 1.8 |
| 6.3 | 1.8 | 1.8, 11.0.3 或更高版本 |



| Oracle JDK 版本 | 说明 |
| --- | --- |
| 1.8u181 或以上版本 | 推荐 |
| 1.8u162 | 推荐 |
| 1.8u141 | 推荐 |
| 1.8u131 | 推荐 |
| 1.8u121 | 推荐 |
| 1.8u111 | 推荐 |
| 1.8u102 | 推荐 |
| 1.8u91 | 推荐 |
| 1.8u74 | 推荐 |
| 1.8u31 | 不能低于该版本 |


| OpenJDK 版本  | 说明 |
| --- | --- |
| 1.8u212 或以上版本  | 推荐  |
| 1.8u181  | 不能低于该版本 |

官方对 JDK 要求说明：[传送门](https://docs.cloudera.com/documentation/enterprise/6/release-notes/topics/rg_java_requirements.html#java_requirements)

Oracle 1.8u261 下载: [传送门](https://download.oracle.com/otn/java/jdk/8u261-b12/a4634525489241b9a9e1aa73d9e118e6/jdk-8u261-linux-x64.tar.gz)

##### 2. Scala 2.13.0
[https://www.scala-lang.org/download/](https://www.scala-lang.org/download/)

##### 3. Mysql driver 5.1.47
[https://mvnrepository.com/artifact/mysql/mysql-connector-java/5.1.47](https://mvnrepository.com/artifact/mysql/mysql-connector-java/5.1.47)

##### 4. Mysql 5.7
[https://dev.mysql.com/downloads/mysql/5.7.html](https://dev.mysql.com/downloads/mysql/5.7.html)
[https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.30-1.el7.x86_64.rpm-bundle.tar](https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.30-1.el7.x86_64.rpm-bundle.tar)

##### 5. Cloudera Manger
[https://archive.cloudera.com/cm6/6.2.0/redhat7/yum/RPMS/x86_64/](https://archive.cloudera.com/cm6/6.2.0/redhat7/yum/RPMS/x86_64/)

##### 6. Parcels
[https://archive.cloudera.com/cdh6/6.3.2/parcels/](https://archive.cloudera.com/cdh6/6.3.2/parcels/)


#### 环境准备（v2.1 新增）

**方式 1：交互式初始化（推荐首次使用）**

```bash
cd /root/setup_cdh_cluster

# 一条命令完成所有环境准备
make init

# 特点：
# ✓ 交互式确认每个步骤
# ✓ 配置信息可视化显示
# ✓ 友好的错误提示
# ✓ 美观的进度显示
# ✓ 灵感来自 playground 项目
```

**方式 2：自动化准备（适合熟悉环境的用户）**

```bash
cd /root/setup_cdh_cluster

# 1. 创建配置文件
make env-file
vi .env  # 编辑配置

# 2. 一键准备环境
make prepare-env

# 3. 安装Python依赖
make install-deps

# 4. 运行环境测试
make test-env
```

#### 部署

**方法1：使用Makefile（推荐）**
```bash
cd /root/setup_cdh_cluster

# 查看可用命令
make help

# 完整部署流程
make full-deploy

# 或分步执行
make check          # 检查环境
make deploy         # 部署集群
make verify         # 验证部署
make test-full      # 测试部署
```

**方法2：使用管理脚本**
```bash
cd /root/setup_cdh_cluster
chmod +x scripts/manage_cluster.sh

# 一键部署
./scripts/manage_cluster.sh deploy

# 验证部署
./scripts/manage_cluster.sh verify
```

**方法3：使用ansible-playbook**
```bash
ansible-playbook -i /root/setup_cdh_cluster/ansible/node_group/hosts /root/setup_cdh_cluster/ansible/deploy_cdh.yml
```

#### 🌐 访问 Cloudera Manager Web 界面

部署完成后，等待 **3-5 分钟** 让 CM Server 完全启动，然后访问：

**主访问地址：**
```
http://node01:7180
```

**备用地址（使用 IP）：**
```
http://192.168.56.151:7180
```

**登录凭证：**
```
用户名: admin
密码:   admin
```

**启动确认：**
```bash
# 查看启动日志
tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log

# 等待看到 "Started Jetty server" 表示启动成功

# 检查端口
netstat -tlnp | grep 7180
```

📖 **详细访问指南**：[WEB_ACCESS_GUIDE.md](WEB_ACCESS_GUIDE.md)

## 运维和故障排查

### 健康检查
```bash
# 全面健康检查（推荐）
make health-check

# 深度诊断（依赖关系分析）
make diagnose

# 查看服务状态
make status
```

### 🛠️ 常见问题一键修复（v2.2 新增）

#### 1. 一键修复所有已知问题（推荐）⭐
```bash
make fix-all
```
**功能：**
- ✅ 修复 Agent 配置错误（server_host=localhost）
- ✅ 禁用 BitTorrent 分发（改用 HTTP）
- ✅ 配置 SSH 免警告
- ✅ 修复文件权限
- ✅ 准备 Parcel 分发

#### 2. Agent 配置错误
**问题：** CM 界面只显示 1 个节点，其他节点 Agent 无法连接

**修复：**
```bash
make fix-agent
```

#### 3. Parcel 分发失败
**错误：** `Failure due to stall on seeded torrent`

**修复：**
```bash
# 方式 1: 自动修复（推荐）
make fix-all

# 方式 2: 手动分发
make distribute-parcel
```

#### 4. MySQL 密码问题
```bash
make reset-mysql
```

#### 5. CM Server 连接错误
**错误信息：** `Communications link failure`

**原因：** CM Server 在 MySQL 之前启动

**修复：**
```bash
make fix-cm-mysql
```

#### 6. 服务启动顺序错误
```bash
make restart-services
```

#### 7. 完整诊断流程
```bash
# 1. 健康检查
make health-check

# 2. 发现问题后深度诊断
make diagnose

# 3. 一键修复（推荐）
make fix-all

# 4. 或根据诊断结果选择具体修复方案
make fix-agent           # Agent 配置问题
make distribute-parcel   # Parcel 分发问题
make fix-cm-mysql        # CM 连接问题
make reset-mysql         # MySQL 密码问题
make restart-services    # 服务顺序问题
```

### 🔧 修复工具汇总（v2.2）

| 工具 | 命令 | 说明 |
|-----|------|-----|
| ⭐ 一键修复 | `make fix-all` | 修复所有已知问题（推荐） |
| Agent 修复 | `make fix-agent` | 修复 Agent 配置错误 |
| Parcel 分发 | `make distribute-parcel` | 手动分发 CDH Parcel |
| 健康检查 | `make health-check` | 全面检查服务状态和依赖关系 |
| 深度诊断 | `make diagnose` | 分析启动顺序和错误日志 |
| CM MySQL 修复 | `make fix-cm-mysql` | 修复 CM Server MySQL 连接 |
| MySQL 重置 | `make reset-mysql` | 重置 MySQL 密码 |
| 服务重启 | `make restart-services` | 按正确顺序重启所有服务 |

📚 **详细文档：**
- [故障排查指南](doc/故障排查指南.md)
- [项目修复总结](doc/项目修复总结.md) - ⭐ v2.2 新增
- [集群启停指南](doc/集群启停指南.md) - ⭐ v2.2 新增
- [修复快速参考](FIXES_QUICK_REFERENCE.md) - ⭐ v2.2 新增

## 📚 文档中心

### 入门指南
- [快速开始指南](doc/快速开始指南.md) - 新手入门教程
- [交互式初始化指南](doc/交互式初始化指南.md) - ⭐ 优雅的环境初始化（灵感来自 playground）
- [base_file 目录准备](doc/base_file目录准备指南.md) - 安装包准备指南

### 部署相关
- [部署说明](doc/部署说明.md) - 详细部署步骤
- [Web 访问指南](WEB_ACCESS_GUIDE.md) - 🌐 Cloudera Manager Web 界面访问
- [部署警告说明](doc/部署警告说明.md) - 部署过程中警告的解释

### 运维管理（v2.2 更新）
- [集群启停指南](doc/集群启停指南.md) - ⭐ 启动、停止、重启操作
- [项目修复总结](doc/项目修复总结.md) - ⭐ 所有已修复问题汇总
- [修复快速参考](FIXES_QUICK_REFERENCE.md) - ⭐ 快速修复命令卡片
- [故障排查指南](doc/故障排查指南.md) - 问题诊断和修复

### 高级操作
- [删除集群指南](doc/删除集群指南.md) - ⚠️ 完全删除 CDH 集群（危险操作）
- [项目优化说明](doc/项目优化说明.md) - 优化记录
- [2025-11-12 全面优化](doc/2025-11-12-项目全面优化.md) - v2.1 工程化优化说明

## 更新日志

### v2.2 (2025-11-12) - 稳定性修复版
- 🔧 **新增** `make fix-all` - 一键修复所有已知问题（推荐）
- 🔧 **新增** `make fix-agent` - 修复 Agent 配置错误
- 🔧 **新增** `make distribute-parcel` - 手动分发 CDH Parcel
- 🐛 **修复** CM Agent 配置错误（server_host=localhost 问题）
- 🐛 **修复** Parcel BitTorrent 分发失败问题
- 🐛 **修复** SSH known_hosts 警告干扰问题
- ✨ **优化** 集群启停脚本（`cluster_control.sh`）
  - 自动验证和修复 Agent 配置
  - 智能等待 CM Server 启动
  - 详细的状态反馈和错误处理
- ✨ **更新** Ansible 部署 playbook，防止配置缺失
- 📝 **新增** 项目修复总结文档
- 📝 **新增** 集群启停指南
- 📝 **新增** 修复快速参考卡片

### v2.1 (2025-11-12) - 工程化优化版
- ✨ 新增 `make init` 交互式环境初始化（灵感来自 playground 项目）
- ✨ 新增 `make post-check` 部署后完整检查
- ✨ 新增 `make delall` 完全删除 CDH 集群（双重确认保护）
- ✨ 新增 `make health-check-v2` 优化版健康检查（美化输出）
- ✨ 新增 `make test-ssh` SSH 免密登录状态测试
- ✨ 新增 requirements.txt 依赖管理
- ✨ 新增 .env 环境配置系统
- ✨ 新增 Docker 完整支持
- ✨ 新增自动化测试框架
- ✨ 新增统一日志模块（`lib/output_formatter.sh`）
- ✨ 新增配置管理模块
- 🔧 优化 Makefile，增加测试和Docker命令
- 🔧 优化项目结构，提高模块化
- 🔧 优化部署完成提示，显示 Web 访问地址
- 🔧 优化所有脚本输出，统一美化风格
- 🐛 修复 Python 3.6 兼容性问题
- 📝 完善文档体系（新增交互式初始化、部署警告说明、删除集群指南等）

### v2.0 (2025-11-11)
- ✅ Python 3.8+ 支持
- ✅ 存储优化
- ✅ 服务依赖管理
- ✅ 健康检查功能

## ❓ FAQ

### Q: 下载虚拟机后如何使用？
**A:** 按照以下步骤：
1. 解压虚拟机文件
2. 使用 VirtualBox/VMware 导入虚拟机
3. 配置每个虚拟机为 4核CPU + 4GB内存
4. 启动所有3个节点
5. 准备安装包到 `/opt/base_file`
6. 在 node01 上运行 `make init` 初始化环境
7. 运行 `make deploy` 开始部署

### Q: CM 界面只显示 1 个节点？（v2.2 新增）
**A:** 这是 Agent 配置错误，使用一键修复：
```bash
make fix-all
```
或者只修复 Agent：
```bash
make fix-agent
```

### Q: Parcel 分发失败？（v2.2 新增）
**A:** 错误信息：`Failure due to stall on seeded torrent`

**解决方案：**
```bash
# 方式 1: 一键修复（推荐）
make fix-all

# 方式 2: 手动分发
make distribute-parcel
```

### Q: cloudera-scm-server 无法启动？
**A:** 常见原因和解决方案：

1. **MySQL 连接错误**
   ```bash
   # 查看日志确认错误
   tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log
   
   # 如果看到 "Communications link failure"
   make fix-cm-mysql
   ```

2. **MySQL 密码错误**
   ```bash
   make reset-mysql
   ```

3. **端口被占用**
   ```bash
   make force-stop
   make start
   ```

### Q: 遇到问题不知道如何修复？（v2.2 新增）
**A:** 使用一键修复命令：
```bash
make fix-all
```
这会自动修复所有已知问题，包括：
- Agent 配置错误
- BitTorrent 分发问题
- SSH 警告
- 文件权限问题

### Q: 如何查看详细日志？
```bash
# CM Server 日志
tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log

# MySQL 日志
tail -f /var/log/mysqld.log

# 部署日志
tail -f /var/log/cdh_deploy.log

# systemd 日志
journalctl -u cloudera-scm-server -n 100
```

### Q: 服务启动顺序是什么？
正确顺序：
1. MySQL (3306)
2. httpd (80)
3. cloudera-scm-server (7180)
4. cloudera-scm-agent (7182)

使用 `make diagnose` 可以检查实际启动顺序。

### Q: 与 playground 项目有什么关系？
**A:** 本项目深度参考了 [playground](https://gitee.com/several-boats/playground.git) 的设计理念：

**🔑 核心灵感 - SSH 免密登录（必看！）**
- ✅ **完全使用 playground 的方案**：`playground/systems/sshFreeLogin.sh`
- ✅ **expect 自动化**：自动处理 `yes/no` 和密码输入
- ✅ **批量配置**：自动配置所有节点的免密登录
- ✅ **验证机制**：自动检查免密登录是否成功

**其他参考之处：**
- 交互式初始化（`make init` vs `playground init`）
- YUM 源配置（`set_centos_repo_to_aliyun`）
- 系统依赖自动安装（`check_dependency`）
- 系统环境配置（防火墙、SELinux、时间同步）
- 集群节点同步（`update_all`）
- 成功提示框（ASCII 艺术）

**本项目的增强：**
- 专注于 CDH 集群部署
- 集成 Ansible 自动化
- 完善的诊断工具
- Makefile 统一管理
- 彩色日志输出
- 详细的错误处理
- `.env` 配置文件管理

**playground 使用示例：**
```bash
# playground 项目使用方式
cd /root
git clone https://gitee.com/several-boats/playground.git
cd playground
chmod +x playground.sh
./playground.sh install
playground init
# 是否安装 JDK? (yes/no): no
```

**本项目使用方式：**
```bash
# 本项目使用方式
cd /root
git clone <your-repo>/setup_cdh_cluster.git
cd setup_cdh_cluster
make init
# 按提示操作，无需安装 JDK（已包含在安装包中）
```

## Docker部署（v2.1 新增）

```bash
# 构建镜像
make docker-build

# 启动容器
make docker-up

# 进入容器
make docker-exec

# 在容器内部署
make deploy

# 查看日志
make docker-logs

# 停止容器
make docker-down
```

## 测试（v2.1 新增）

```bash
# 环境测试
make test-env

# 完整测试（需要先部署）
make test-full

# 查看测试报告
cat test_output/test_report_*.txt
```

## 项目结构（v2.1 更新）

```
setup_cdh_cluster/
├── ansible/              # Ansible脚本
├── scripts/              # Shell脚本
├── doc/                  # 文档目录
├── lib/                  # 公共库（新增）
│   ├── logger.py        # 日志模块
│   └── config.py        # 配置模块
├── tests/                # 测试目录（新增）
│   ├── test_environment.py
│   ├── test_deployment.py
│   └── run_tests.sh
├── requirements.txt      # Python依赖（新增）
├── .env.template         # 环境配置模板（新增）
├── Dockerfile            # Docker镜像（新增）
├── docker-compose.yml    # Docker编排（新增）
├── Makefile              # 构建脚本（增强）
└── README.md             # 项目说明
```

## TODO list
1. 集群进行水平扩展时，对新节点初始化配置
2. 添加自动化备份和恢复功能
3. 支持多版本 CDH 部署
4. Prometheus/Grafana 监控集成
5. Web 管理界面

## 参考
- 官方安装步骤: [https://docs.cloudera.com/documentation/enterprise/6/6.2/topics/installation.html](https://docs.cloudera.com/documentation/enterprise/6/6.2/topics/installation.html)
- MySQL 安装指南: [https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/cm_ig_mysql.html](https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/cm_ig_mysql.html)
