# SSH 免密登录配置指南

**三节点集群 SSH 配置 | Copyright © 2025 RaynLiu**

---

## 🎯 为什么需要 SSH 免密登录？

CDH 集群管理需要在节点之间频繁通信，SSH 免密登录是必需的：

- ✅ Ansible 自动化需要免密登录
- ✅ 启动/停止服务需要免密登录
- ✅ 健康检查需要免密登录
- ✅ 所有管理命令都需要免密登录

**没有配置 SSH 免密登录，每次执行命令都会要求输入密码！**

---

## 🚀 快速配置（推荐）

### 一条命令完成配置

```bash
cd /root/setup_cdh_cluster
make setup-ssh
```

**就这么简单！** 🎉

---

## 📋 配置信息

### 节点信息

| 节点 | IP 地址 | 密码 | 角色 |
|---|---|---|---|
| node01 | 192.168.56.151 | 123456 | Master |
| node02 | 192.168.56.152 | 123456 | Slave |
| node03 | 192.168.56.153 | 123456 | Slave |

### 配置内容

1. **SSH 密钥对** - RSA 2048 位
2. **公钥位置** - `~/.ssh/id_rsa.pub`
3. **私钥位置** - `~/.ssh/id_rsa`
4. **授权文件** - `~/.ssh/authorized_keys`（在目标节点）

---

## 🔧 自动配置脚本说明

### 脚本位置

```
/root/setup_cdh_cluster/scripts/setup_ssh_keys.sh
```

### 配置步骤

脚本会自动执行以下步骤：

#### 1. 安装依赖工具

```bash
yum install -y sshpass
```

**sshpass** 用于自动输入 SSH 密码。

#### 2. 生成 SSH 密钥对

```bash
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
```

- 类型：RSA
- 长度：2048 位（默认）
- 无密码保护

#### 3. 配置 SSH 客户端

创建 `~/.ssh/config`：
```
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    ConnectTimeout=10
```

- **StrictHostKeyChecking no** - 不检查主机密钥
- **UserKnownHostsFile=/dev/null** - 不保存已知主机
- **ConnectTimeout=10** - 连接超时 10 秒

#### 4. 复制公钥到所有节点

```bash
sshpass -p "123456" ssh-copy-id -o StrictHostKeyChecking=no root@192.168.56.151
sshpass -p "123456" ssh-copy-id -o StrictHostKeyChecking=no root@192.168.56.152
sshpass -p "123456" ssh-copy-id -o StrictHostKeyChecking=no root@192.168.56.153
```

#### 5. 测试免密连接

```bash
ssh node01 "hostname"
ssh node02 "hostname"
ssh node03 "hostname"
```

---

## ✅ 验证配置

### 测试免密连接

```bash
# 测试 node01
ssh node01 "hostname"
# 应输出: node01

# 测试 node02
ssh node02 "hostname"
# 应输出: node02

# 测试 node03
ssh node03 "hostname"
# 应输出: node03
```

**不应该要求输入密码！**

---

### 使用管理命令测试

```bash
# 1. 检查节点连通性
make nodes

# 2. 查看服务状态
make status

# 3. 健康检查
make health
```

**所有命令都不应该要求输入密码！**

---

## 🛠️ 手动配置方法

如果自动配置脚本失败，可以手动配置：

### 步骤 1: 安装 sshpass

```bash
yum install -y sshpass
```

### 步骤 2: 生成 SSH 密钥

```bash
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
```

按提示操作，全部按回车。

### 步骤 3: 复制公钥到 node01

```bash
ssh-copy-id root@192.168.56.151
# 输入密码: 123456
```

### 步骤 4: 复制公钥到 node02

```bash
ssh-copy-id root@192.168.56.152
# 输入密码: 123456
```

### 步骤 5: 复制公钥到 node03

```bash
ssh-copy-id root@192.168.56.153
# 输入密码: 123456
```

### 步骤 6: 测试连接

```bash
ssh node01 "hostname"  # 不需要密码
ssh node02 "hostname"  # 不需要密码
ssh node03 "hostname"  # 不需要密码
```

---

## 🔍 故障排查

### 问题 1: ssh-copy-id 失败

**错误**：
```
Permission denied (publickey,password)
```

**解决方案**：

```bash
# 1. 检查 SSH 服务
ssh node02 "systemctl status sshd"

# 2. 检查密码是否正确
ssh root@192.168.56.152
# 手动输入密码: 123456

# 3. 检查 SSH 配置
ssh node02 "cat /etc/ssh/sshd_config | grep PasswordAuthentication"
# 应该是: PasswordAuthentication yes

# 4. 如果是 no，修改配置
ssh node02 "sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config"
ssh node02 "systemctl restart sshd"
```

---

### 问题 2: 免密登录不生效

**现象**：配置后仍要求输入密码

**解决方案**：

```bash
# 1. 检查权限
ls -la ~/.ssh/
# id_rsa 应该是 600
# id_rsa.pub 应该是 644
# authorized_keys 应该是 600

# 2. 修复权限
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/authorized_keys

# 3. 检查目标节点的 authorized_keys
ssh node02 "ls -la ~/.ssh/authorized_keys"
ssh node02 "cat ~/.ssh/authorized_keys"

# 4. 检查 SELinux
getenforce
# 如果是 Enforcing，可以临时关闭
setenforce 0
```

---

### 问题 3: 连接超时

**错误**：
```
ssh: connect to host node02 port 22: Connection timed out
```

**解决方案**：

```bash
# 1. 检查网络连通性
ping 192.168.56.152

# 2. 检查防火墙
systemctl status firewalld

# 3. 检查 SSH 端口
netstat -tlnp | grep 22

# 4. 临时关闭防火墙测试
systemctl stop firewalld
```

---

### 问题 4: 主机名解析失败

**错误**：
```
ssh: Could not resolve hostname node02: Name or service not known
```

**解决方案**：

```bash
# 检查 /etc/hosts
cat /etc/hosts

# 应该包含：
# 192.168.56.151 node01
# 192.168.56.152 node02
# 192.168.56.153 node03

# 如果没有，添加：
cat >> /etc/hosts << EOF
192.168.56.151 node01
192.168.56.152 node02
192.168.56.153 node03
EOF
```

---

## 📊 SSH 密钥管理

### 查看公钥

```bash
cat ~/.ssh/id_rsa.pub
```

### 查看私钥

```bash
cat ~/.ssh/id_rsa
```

**注意：私钥是敏感信息，不要泄露！**

### 删除并重新生成密钥

```bash
# 删除旧密钥
rm -f ~/.ssh/id_rsa ~/.ssh/id_rsa.pub

# 重新生成
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

# 重新配置
make setup-ssh
```

---

## 🔒 安全建议

### 1. 使用密钥而非密码

✅ **已实现** - SSH 密钥比密码更安全

### 2. 定期更新密钥

```bash
# 每 6-12 个月更新一次
rm -f ~/.ssh/id_rsa*
make setup-ssh
```

### 3. 限制 SSH 访问

编辑 `/etc/ssh/sshd_config`：
```
PermitRootLogin without-password
PasswordAuthentication no
```

**注意：设置后只能通过密钥登录！**

### 4. 使用防火墙限制访问

```bash
# 只允许特定 IP 访问 SSH
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.56.0/24" port protocol="tcp" port="22" accept'
firewall-cmd --reload
```

---

## 📝 最佳实践

### 1. 首次部署时配置

```bash
# 第一步：配置 SSH 免密登录
make setup-ssh

# 第二步：准备环境
make prepare-env

# 第三步：部署集群
make deploy
```

### 2. 定期测试连接

```bash
# 每周检查一次
make nodes
```

### 3. 保持密钥同步

如果重装了某个节点，需要重新配置：

```bash
# 重新配置单个节点
sshpass -p "123456" ssh-copy-id root@192.168.56.152

# 或重新配置所有节点
make setup-ssh
```

---

## 🎯 快速参考

### 核心命令

| 命令 | 用途 |
|---|---|
| `make setup-ssh` | 自动配置免密登录 |
| `make nodes` | 测试连接 |
| `ssh node01 "hostname"` | 手动测试 node01 |
| `ssh node02 "hostname"` | 手动测试 node02 |
| `ssh node03 "hostname"` | 手动测试 node03 |

### 重要文件

| 文件 | 说明 |
|---|---|
| `~/.ssh/id_rsa` | 私钥（敏感） |
| `~/.ssh/id_rsa.pub` | 公钥 |
| `~/.ssh/config` | SSH 客户端配置 |
| `~/.ssh/authorized_keys` | 授权的公钥列表 |

### 常用诊断命令

```bash
# 查看 SSH 配置
cat ~/.ssh/config

# 查看公钥
cat ~/.ssh/id_rsa.pub

# 查看授权密钥
cat ~/.ssh/authorized_keys

# 测试连接（详细模式）
ssh -v node02 "hostname"

# 检查权限
ls -la ~/.ssh/
```

---

## 📞 获取帮助

```bash
# 查看所有命令
make help

# 查看 SSH 脚本
cat /root/setup_cdh_cluster/scripts/setup_ssh_keys.sh

# 查看文档
cat OPERATIONS_GUIDE.md
cat MULTI_NODE_GUIDE.md
```

---

**文档版本**: v1.0  
**最后更新**: 2025-11-11  
**作者**: RaynLiu

**立即配置： `make setup-ssh` ✅**
