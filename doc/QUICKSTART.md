# CDH 集群快速开始指南

**5 分钟快速部署 CDH 集群 | Copyright © 2025 RaynLiu**

---

## 🎯 环境信息

### 节点配置

| 节点 | IP地址 | 主机名 | 角色 | 密码 |
|---|---|---|---|---|
| Master | 192.168.56.151 | node01 | CM Server + Agent | 123456 |
| Slave | 192.168.56.152 | node02 | Agent | 123456 |
| Slave | 192.168.56.153 | node03 | Agent | 123456 |

### 软件版本

| 组件 | 版本 |
|---|---|
| CDH | 6.2.0 |
| Cloudera Manager | 6.2.0 |
| MySQL | 5.7.30 |
| JDK | 1.8u261 |
| Python | 3.8+ |
| Ansible | 2.8.12+ |
| CentOS | 7.x |

---

## 🚀 快速部署（3 步完成）

### 步骤 1: 首次配置（仅需一次）

```bash
# 1. SSH 到 node01
ssh root@192.168.56.151

# 2. 进入项目目录
cd /root/setup_cdh_cluster

# 3. 修复脚本权限
make fix-permissions

# 4. 配置 SSH 免密登录
make setup-ssh
# 输入节点密码: 123456

# 5. 准备环境
make prepare-env
```

**预期输出**：
```
==========================================
  ✓ 环境准备完成！
==========================================

下一步：
  make deploy    # 开始部署 CDH 集群
```

---

### 步骤 2: 部署集群

```bash
# 部署 CDH 集群
make deploy
```

**部署过程**（约 15-30 分钟）：
- ✅ 配置主机名和 hosts
- ✅ 关闭防火墙和 SELinux
- ✅ 安装 JDK
- ✅ 安装 MySQL（仅 Master 节点）
- ✅ 安装 Cloudera Manager
- ✅ 配置 Parcel 文件
- ✅ 启动所有服务

**如果遇到 MySQL 密码问题**：
```bash
# 重置 MySQL 密码
make reset-mysql

# 重新部署
make deploy
```

---

### 步骤 3: 验证和访问

```bash
# 验证部署
make verify

# 检查所有节点
make nodes

# 启动所有节点
make start-all

# 健康检查
make health
```

**访问 Cloudera Manager**：
- URL: http://192.168.56.151:7180 或 http://node01:7180
- 用户名: `admin`
- 密码: `admin`

---

## 📋 完整命令列表

### 环境准备

```bash
make fix-permissions   # 修复脚本权限
make setup-ssh         # 配置 SSH 免密登录
make prepare-env       # 准备环境
make check-env         # 检查环境
make check             # 检查磁盘空间
```

### 部署管理

```bash
make deploy            # 部署集群
make verify            # 验证部署
make clean             # 清理系统
make cleanup-copies    # 清理复制文件
```

### 多节点管理

```bash
make nodes             # 检查所有节点连通性
make start-all         # 启动所有节点
make stop-all          # 停止所有节点
```

### 服务管理

```bash
make status            # 查看服务状态
make start             # 启动服务
make stop              # 停止服务
make restart           # 重启服务
make force-stop        # 强制停止
```

### 监控诊断

```bash
make health            # 健康检查
make ps                # 查看进程
make ports             # 查看端口
make logs              # 查看日志
```

### 故障修复

```bash
make fix-permissions   # 修复权限
make reset-mysql       # 重置 MySQL 密码
```

### 快捷命令

```bash
make full-deploy       # 完整部署（环境+部署+验证）
make quick-deploy      # 快速部署（清理+部署+验证）
```

---

## 🔧 常见问题解决

### 问题 1: 脚本权限不够

**错误**：
```
execvp: ./scripts/xxx.sh: 权限不够
```

**解决**：
```bash
make fix-permissions
```

---

### 问题 2: SSH 连接需要密码

**错误**：
```
root@node02's password:
```

**解决**：
```bash
make setup-ssh
# 输入所有节点密码: 123456
```

---

### 问题 3: MySQL 密码设置失败

**错误**：
```
ERROR 1045 (28000): Access denied for user 'root'@'localhost'
```

**解决**：
```bash
make reset-mysql
make deploy
```

---

### 问题 4: 节点离线或不可达

**错误**：
```
检查 node02 ... ✗ 离线或不可达
```

**解决**：
```bash
# 1. 确保虚拟机已启动
# 2. 检查网络
ping 192.168.56.152

# 3. 检查 /etc/hosts
cat /etc/hosts | grep node

# 4. 应包含：
# 192.168.56.151 node01
# 192.168.56.152 node02
# 192.168.56.153 node03
```

---

### 问题 5: YUM 源问题

**错误**：
```
无法下载 repodata/repomd.xml
```

**解决**：
```bash
make fix-yum
yum clean all
yum makecache
```

---

## 📊 部署流程图

```
┌─────────────────────────────────────┐
│  1. 首次配置                          │
│  - fix-permissions                  │
│  - setup-ssh                        │
│  - prepare-env                      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  2. 部署集群                          │
│  - make deploy (15-30分钟)           │
│  - 如果 MySQL 失败: reset-mysql      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  3. 验证和启动                        │
│  - make verify                      │
│  - make nodes                       │
│  - make start-all                   │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  4. 访问 Web UI                      │
│  http://node01:7180                 │
│  admin / admin                      │
└─────────────────────────────────────┘
```

---

## 🎯 典型使用场景

### 场景 1: 首次部署

```bash
cd /root/setup_cdh_cluster

# 一键完整部署
make full-deploy

# 或分步执行
make fix-permissions
make setup-ssh
make prepare-env
make deploy
make verify
make start-all
```

---

### 场景 2: 重新部署

```bash
cd /root/setup_cdh_cluster

# 快速重新部署
make quick-deploy

# 或手动
make clean
make deploy
make verify
```

---

### 场景 3: 每天启动集群

```bash
# 1. 启动所有虚拟机（宿主机操作）

# 2. SSH 到 node01
ssh root@192.168.56.151

# 3. 进入项目
cd /root/setup_cdh_cluster

# 4. 检查节点
make nodes

# 5. 启动集群
make start-all

# 6. 验证健康
make health

# 7. 访问 Web UI
firefox http://node01:7180
```

---

### 场景 4: 每天停止集群

```bash
cd /root/setup_cdh_cluster

# 1. 停止所有节点
make stop-all

# 2. 验证停止
make status

# 3. 关闭虚拟机（宿主机操作）
```

---

### 场景 5: 故障排查

```bash
cd /root/setup_cdh_cluster

# 查看进程
make ps

# 查看端口
make ports

# 查看日志
make logs

# 健康检查
make health

# 强制清理
make force-stop
make clean
```

---

## 📝 检查清单

### 部署前检查

- [ ] 所有虚拟机已启动
- [ ] 网络互通（ping 测试）
- [ ] `/etc/hosts` 配置正确
- [ ] 节点密码已知（默认 123456）
- [ ] 磁盘空间充足（至少 50GB）

### 部署后验证

- [ ] `make nodes` 显示所有节点在线
- [ ] `make status` 显示所有服务运行
- [ ] `make health` 通过健康检查
- [ ] Web UI 可访问 (http://node01:7180)
- [ ] 可以使用 admin/admin 登录

---

## 🔗 相关文档

- **操作指南**: `OPERATIONS_GUIDE.md` - 详细的运维操作手册
- **多节点管理**: `MULTI_NODE_GUIDE.md` - 三节点集群管理
- **SSH 配置**: `SSH_SETUP_GUIDE.md` - SSH 免密登录配置
- **快速参考**: `QUICK_REFERENCE.md` - 命令快速查询

---

## 📞 获取帮助

```bash
# 查看所有可用命令
make help

# 查看管理脚本帮助
./scripts/manage_cluster.sh help

# 查看文档列表
ls -1 *.md
```

---

## 🎉 部署成功标志

当你看到以下内容时，说明部署成功：

```
==========================================
  ✓ 所有节点在线
==========================================

==========================================
  启动完成汇总
==========================================
  Master 节点 (node01): ✓ 已启动
  Slave 节点在线: 2/2

  访问 Cloudera Manager:
  URL: http://node01:7180
  用户名: admin | 密码: admin
==========================================
```

**恭喜！现在可以访问 Cloudera Manager 开始使用 CDH 集群！** 🎉

---

**文档版本**: v1.0  
**最后更新**: 2025-11-11  
**作者**: RaynLiu

**立即开始： `make full-deploy` ✅**
