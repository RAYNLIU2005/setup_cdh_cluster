# 快速配置指南

## 📋 默认配置说明

项目已配置好默认值，适用于标准的三节点 CDH 集群部署。

### 默认节点配置

```bash
# 节点信息
node01: 192.168.56.151 (Master)
node02: 192.168.56.152 (Slave)
node03: 192.168.56.153 (Slave)

# SSH 配置
用户名: root
密码: 123456
```

### 配置文件位置

```bash
.env.template  # 配置模板
.env           # 实际配置（首次运行时自动创建）
```

---

## 🚀 快速开始（使用默认配置）

### 方式一：一键初始化（推荐）

```bash
# 1. 进入项目目录
cd /root/setup_cdh_cluster

# 2. 运行交互式初始化
make init
```

**提示：**
- ✅ 检测到 `.env` 文件时，会提示是否使用默认密码，直接按 `y` 即可
- ✅ 未检测到时，直接按回车使用默认密码 `123456`
- ✅ 所有步骤都会自动完成，无需手动输入

### 方式二：单独配置 SSH 免密登录

```bash
# 配置 SSH 免密登录
make setup-ssh
```

**使用默认配置：**
```
是否使用配置文件中的默认密码? (y/n，默认 y): 
[直接按回车或输入 y]
```

---

## ⚙️ 自定义配置

### 1. 创建配置文件

```bash
# 从模板创建配置文件
make env-file

# 或手动复制
cp .env.template .env
```

### 2. 修改配置

编辑 `.env` 文件，根据实际情况修改：

```bash
vi .env
```

**关键配置项：**

```bash
# 节点配置
MASTER_NODE=node01
MASTER_IP=192.168.56.151

SLAVE_NODE_1=node02
SLAVE_IP_1=192.168.56.152

SLAVE_NODE_2=node03
SLAVE_IP_2=192.168.56.153

# SSH 配置（修改为你的实际密码）
SSH_USER=root
SSH_PASSWORD=你的实际密码

# MySQL 配置
MYSQL_ROOT_PASSWORD=Cloudera!20200801
```

### 3. 运行初始化

```bash
make init
```

---

## 🔧 常用命令

### 环境准备

```bash
make init            # 交互式初始化（推荐）
make prepare-env     # 自动化初始化
make setup-ssh       # 配置 SSH 免密登录
make test-ssh        # 测试 SSH 连接
make fix-yum         # 修复 YUM 源
make diagnose-yum    # YUM 源诊断
```

### 部署管理

```bash
make deploy          # 部署 CDH 集群
make verify          # 验证部署
make status          # 查看状态
make health-check    # 健康检查
```

---

## ❓ 常见问题

### Q1: SSH 配置失败？

**原因：**
- 节点未启动或网络不通
- 密码错误
- 防火墙阻止

**解决方案：**

```bash
# 1. 检查节点连通性
ping node01
ping node02
ping node03

# 2. 检查 SSH 服务
systemctl status sshd

# 3. 运行诊断
make test-ssh

# 4. 手动配置（如果自动配置失败）
ssh-copy-id root@node01
ssh-copy-id root@node02
ssh-copy-id root@node03
```

### Q2: YUM 缓存重建失败？

**解决方案：**

```bash
# 1. 运行诊断
make diagnose-yum

# 2. 修复 YUM 源
make fix-yum

# 3. 检查网络和时间
ping mirrors.aliyun.com
date
```

### Q3: 如何修改默认密码？

编辑 `.env` 文件：

```bash
vi .env

# 修改这一行
SSH_PASSWORD=你的新密码
```

---

## 📝 注意事项

### ⚠️ 安全提示

1. **密码安全**：
   - `.env` 文件包含敏感信息，不会被提交到 Git
   - 生产环境建议使用强密码
   - 定期更换密码

2. **网络安全**：
   - 确保集群在安全的内网环境
   - 配置防火墙规则
   - 限制 SSH 访问

### ✅ 部署前检查

```bash
# 1. 检查磁盘空间（至少 25GB）
make check-disk

# 2. 检查环境准备
make check-env

# 3. 检查节点连通性
make check-nodes
```

---

## 🎯 完整部署流程

### 标准流程（使用默认配置）

```bash
# Step 1: 初始化环境
make init
# 提示使用默认密码时，按 y

# Step 2: 检查环境
make check-env

# Step 3: 检查磁盘
make check-disk

# Step 4: 部署 CDH
make deploy

# Step 5: 验证部署
make verify

# Step 6: 健康检查
make health-check

# Step 7: 访问 Cloudera Manager
# http://node01:7180 (admin/admin)
```

### 自定义流程

```bash
# Step 1: 创建配置
make env-file

# Step 2: 编辑配置
vi .env

# Step 3: 初始化
make init

# Step 4: 部署
make deploy
```

---

## 📚 更多帮助

```bash
# 查看所有命令
make help

# 查看详细文档
cat README.md
```

---

**Copyright © 2025 RaynLiu**  
**Email:** liuyu1_j6go@stu.cqie.edu.cn
