# CDH 集群运维指南

**Copyright © 2025 RaynLiu. All Rights Reserved.**

---

## 📋 目录

1. [快速开始](#快速开始)
2. [环境准备](#环境准备)
3. [服务管理](#服务管理)
4. [监控诊断](#监控诊断)
5. [常见问题](#常见问题)
6. [最佳实践](#最佳实践)

---

## 🚀 快速开始

### 查看所有命令

```bash
cd /root/setup_cdh_cluster
make help
```

### 一键部署（首次部署）

```bash
make full-deploy
```

---

## 🔧 环境准备

### 1. 准备部署环境

```bash
# 一键准备所有环境（YUM、Python、Ansible）
make prepare-env
```

**包含以下步骤**：
- ✅ 修复 YUM 源（阿里云镜像）
- ✅ 安装 Python 3 + pip
- ✅ 配置 pip 国内镜像
- ✅ 安装 Ansible 2.9.27
- ✅ 修复所有节点 YUM 源
- ✅ 检查环境状态

### 2. 单独执行环境准备步骤

```bash
# 修复 YUM 源
make fix-yum

# 安装 Python 3
make setup-python

# 安装 Ansible
make install-ansible

# 检查环境
make check-env
```

---

## 🎛️ 服务管理

### 查看服务状态

```bash
make status
```

**输出示例**：
```
=== Master节点 (node01) 服务状态 ===
--- MySQL ---
   Active: active (running)
--- CM Server ---
   Active: active (running)
--- httpd ---
   Active: active (running)

=== 所有节点 CM Agent 状态 ===
node01 | Active: active (running)
node02 | Active: active (running)
node03 | Active: active (running)
```

---

### 启动服务

```bash
make start
```

**启动流程**：
1. 启动 MySQL
2. 启动 httpd
3. 启动 CM Server（等待30秒）
4. 启动所有节点的 CM Agent
5. 显示访问地址

**启动后访问**：
- URL: http://node01:7180
- 用户名: admin
- 密码: admin

---

### 停止服务

```bash
make stop
```

**停止流程**：
1. 停止所有节点的 CM Agent
2. 停止 CM Server
3. 停止 httpd
4. 停止 MySQL
5. **自动清理残留进程**
6. **重置失败状态**

---

### 重启服务

```bash
make restart
```

**等效于**：
```bash
make stop
# 等待 5 秒
make start
```

---

### 强制停止（彻底清理）

```bash
make force-stop
```

**使用场景**：
- 普通停止失败
- 有残留进程
- 端口被占用
- 服务异常无法停止

**执行操作**：
1. 停止所有 systemd 服务
2. 强制 kill 所有 cloudera 进程
3. 强制 kill supervisord 进程
4. 重置所有服务状态
5. 验证清理结果

---

## 🏥 监控诊断

### 健康检查

```bash
make health
```

**检查项目**：
1. ✅ 服务状态（MySQL, CM Server, httpd, CM Agent）
2. ✅ 端口监听（7180, 3306）
3. ✅ 磁盘空间
4. ✅ 节点连通性
5. ✅ 进程数量

**输出示例**：
```
========================================
  CDH 集群健康检查
========================================

[1/5] 服务状态
  ✓ cloudera-scm-server: active
  ✓ cloudera-scm-agent: active
  ✓ mysqld: active
  ✓ httpd: active

[2/5] 端口检查
  ✓ CM Server 端口 7180 已监听
  ✓ MySQL 端口 3306 已监听

[3/5] 磁盘空间
  / 分区使用: 45% (可用: 25G)

[4/5] 节点连通性
  ✓ 所有节点连通

[5/5] 进程检查
  Cloudera 进程数: 15

========================================
  ✓ 集群状态: 健康
========================================
```

---

### 查看进程

```bash
make ps
```

**显示**：
- Master 节点所有 CDH 相关进程
- 所有节点的 Cloudera 进程统计

---

### 查看端口

```bash
make ports
```

**检查端口**：
- 7180 (CM Server Web UI)
- 7182 (CM Server Admin)
- 3306 (MySQL)
- 80 (HTTP)

**输出示例**：
```
=== Master 节点 (node01) 端口 ===
--- CM Server (7180) ---
tcp    0   0 0.0.0.0:7180    0.0.0.0:*    LISTEN    20055/java

--- MySQL (3306) ---
tcp    0   0 0.0.0.0:3306    0.0.0.0:*    LISTEN    18234/mysqld

--- HTTP (80) ---
tcp6   0   0 :::80           :::*         LISTEN    17823/httpd
```

---

### 查看日志

```bash
make logs
```

**显示最近50行部署日志**：
- 日志文件：`/var/log/cdh_deploy.log`

**查看完整日志**：
```bash
tail -f /var/log/cdh_deploy.log
```

**查看 CM Server 日志**：
```bash
tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log
```

---

## 🛠️ 常见问题

### 1. 停止服务后有残留进程

**问题**：
```bash
make stop
# 仍有进程残留
ps aux | grep cloudera
```

**解决方案**：
```bash
# 使用强制停止
make force-stop
```

---

### 2. 服务启动失败

**问题**：
```
systemctl status cloudera-scm-server
# Active: failed (Result: exit-code)
```

**解决方案**：
```bash
# 1. 重置失败状态
systemctl reset-failed

# 2. 检查日志
tail -100 /var/log/cloudera-scm-server/cloudera-scm-server.log

# 3. 重新启动
make start
```

---

### 3. CM Server 无法访问

**问题**：
```
无法访问 http://node01:7180
```

**排查步骤**：
```bash
# 1. 检查健康状态
make health

# 2. 检查端口
make ports

# 3. 检查防火墙
systemctl status firewalld

# 4. 查看日志
tail -100 /var/log/cloudera-scm-server/cloudera-scm-server.log
```

---

### 4. Agent 无法连接到 Server

**问题**：
```
Agent 日志显示连接超时
```

**解决方案**：
```bash
# 1. 检查 Server 是否运行
systemctl status cloudera-scm-server

# 2. 检查网络连通性
ping node01

# 3. 检查配置文件
cat /etc/cloudera-scm-agent/config.ini | grep server_host

# 4. 重启 Agent
systemctl restart cloudera-scm-agent
```

---

### 5. 磁盘空间不足

**问题**：
```
df -h
# / 分区使用 95%
```

**解决方案**：
```bash
# 1. 清理临时文件
make clean

# 2. 清理复制文件（使用软链接）
make cleanup-copies

# 3. 检查磁盘空间
make check
```

---

### 6. node02/03 连接失败

**问题**：
```
node02 | UNREACHABLE! => No route to host
```

**原因**：
- 虚拟机已关机
- 网络断开
- SSH 服务未运行

**解决方案**：
```bash
# 1. 检查节点是否在线
ping node02
ping node03

# 2. 启动虚拟机

# 3. 检查 SSH 服务
ssh node02 "systemctl status sshd"

# 4. 测试连通性
ansible all_node -i /root/setup_cdh_cluster/ansible/node_group/hosts -m ping
```

---

## 💡 最佳实践

### 1. 日常启停顺序

#### 启动顺序
```bash
# 1. 确保所有节点在线
ping node02 && ping node03

# 2. 启动服务
make start

# 3. 健康检查
make health

# 4. 访问 Web UI
firefox http://node01:7180
```

#### 停止顺序
```bash
# 1. 通过 Web UI 停止所有集群服务

# 2. 停止 CDH 基础服务
make stop

# 3. 验证停止
make status
```

---

### 2. 定期维护

#### 每日
```bash
# 检查健康状态
make health

# 检查磁盘空间
make check
```

#### 每周
```bash
# 清理临时文件
make clean

# 检查日志
make logs
```

#### 每月
```bash
# 清理复制文件（如果磁盘空间紧张）
make cleanup-copies

# 备份配置
# 手动备份 /etc/cloudera-scm-* 目录
```

---

### 3. 故障处理流程

```bash
# 1. 健康检查
make health

# 2. 查看进程
make ps

# 3. 查看端口
make ports

# 4. 查看日志
make logs

# 5. 如果需要重启
make restart

# 6. 如果普通重启失败
make force-stop
make start
```

---

### 4. 节省磁盘空间

```bash
# 1. 使用软链接替代复制文件
make cleanup-copies

# 2. 定期清理临时文件
make clean

# 3. 检查大文件
du -sh /opt/* | sort -h
du -sh /var/log/* | sort -h
```

---

## 📞 获取帮助

### 命令帮助

```bash
# Makefile 帮助
make help

# 管理脚本帮助
./scripts/manage_cluster.sh help
```

### 日志位置

| 组件 | 日志路径 |
|---|---|
| **部署日志** | `/var/log/cdh_deploy.log` |
| **CM Server** | `/var/log/cloudera-scm-server/` |
| **CM Agent** | `/var/log/cloudera-scm-agent/` |
| **MySQL** | `/var/log/mysqld.log` |
| **httpd** | `/var/log/httpd/` |

---

## 🔗 快速参考

### 常用命令速查

| 操作 | 命令 |
|---|---|
| **查看帮助** | `make help` |
| **健康检查** | `make health` |
| **启动服务** | `make start` |
| **停止服务** | `make stop` |
| **重启服务** | `make restart` |
| **强制停止** | `make force-stop` |
| **查看状态** | `make status` |
| **查看进程** | `make ps` |
| **查看端口** | `make ports` |
| **查看日志** | `make logs` |
| **清理系统** | `make clean` |
| **释放空间** | `make cleanup-copies` |

---

**文档版本**: v2.0  
**最后更新**: 2025-11-11  
**作者**: RaynLiu
