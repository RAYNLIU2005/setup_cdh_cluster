# CDH 集群快速参考

**快速查询常用命令 | Copyright © 2025 RaynLiu**

---

## 📋 查看帮助

```bash
make help                 # 查看所有命令
./scripts/manage_cluster.sh help  # 脚本帮助
```

---

## 🚀 部署管理

```bash
make prepare-env         # 准备环境（YUM、Python、Ansible）
make check               # 检查磁盘空间
make clean               # 清理临时文件
make deploy              # 部署 CDH 集群
make verify              # 验证部署
make full-deploy         # 完整部署（环境+部署+验证）
make quick-deploy        # 快速部署（清理+部署+验证）
```

---

## 🎛️ 服务管理

```bash
make status              # 查看服务状态
make start               # 🚀 启动所有服务
make stop                # 🛑 停止所有服务（自动清理残留）
make restart             # 🔄 重启所有服务
make force-stop          # ⚡ 强制停止（彻底清理）
```

---

## 🏥 监控诊断

```bash
make health              # 🏥 健康检查（全面诊断）
make ps                  # 📊 查看进程
make ports               # 🔌 查看端口占用
make logs                # 📝 查看部署日志
```

---

## 🔧 手动操作

### 服务控制

```bash
# Master 节点
systemctl start/stop/restart cloudera-scm-server
systemctl start/stop/restart cloudera-scm-agent
systemctl start/stop/restart mysqld
systemctl start/stop/restart httpd

# 所有节点
ansible all_node -i /root/setup_cdh_cluster/ansible/node_group/hosts \
  -m service -a "name=cloudera-scm-agent state=started/stopped/restarted"
```

### 查看状态

```bash
systemctl status cloudera-scm-server
systemctl status cloudera-scm-agent
systemctl status mysqld
systemctl status httpd
```

### 查看日志

```bash
# 部署日志
tail -f /var/log/cdh_deploy.log

# CM Server 日志
tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log

# CM Agent 日志
tail -f /var/log/cloudera-scm-agent/cloudera-scm-agent.log

# MySQL 日志
tail -f /var/log/mysqld.log
```

### 查看进程

```bash
# 所有 Cloudera 进程
ps aux | grep cloudera | grep -v grep

# 按进程名查看
ps aux | grep -E "cloudera-scm-server|cloudera-scm-agent|supervisord"
```

### 查看端口

```bash
# 所有监听端口
netstat -tlnp

# 特定端口
netstat -tlnp | grep 7180   # CM Server
netstat -tlnp | grep 3306   # MySQL
netstat -tlnp | grep 80     # HTTP
```

### 强制清理

```bash
# 杀掉所有 Cloudera 进程
pkill -9 -f cloudera
pkill -9 -f supervisord

# 重置失败状态
systemctl reset-failed

# 清理端口（如果被占用）
lsof -ti:7180 | xargs kill -9
lsof -ti:3306 | xargs kill -9
```

---

## 🌐 访问地址

```
Cloudera Manager Web UI
├─ URL: http://node01:7180
├─ 用户名: admin
└─ 密码: admin

MySQL 数据库
├─ 主机: node01
├─ 端口: 3306
├─ 用户: root
└─ 密码: (部署时设置的密码)
```

---

## 📂 重要目录

```
部署项目
└─ /root/setup_cdh_cluster/

安装包
├─ /opt/base_file/packages/    # RPM、JAR 等
└─ /opt/base_file/parcels/     # CDH Parcel 包

部署目录
└─ /opt/setup_cdh/              # 分发到节点的包

Cloudera
├─ /opt/cloudera/               # CM 安装目录
├─ /opt/cloudera/parcels/       # Parcel 安装目录
└─ /var/lib/cloudera-scm-agent/ # Agent 数据

配置文件
├─ /etc/cloudera-scm-server/    # CM Server 配置
├─ /etc/cloudera-scm-agent/     # CM Agent 配置
└─ /etc/my.cnf                   # MySQL 配置

日志目录
├─ /var/log/cdh_deploy.log                  # 部署日志
├─ /var/log/cloudera-scm-server/            # CM Server 日志
├─ /var/log/cloudera-scm-agent/             # CM Agent 日志
└─ /var/log/mysqld.log                      # MySQL 日志
```

---

## ⚠️ 故障排查

### 服务启动失败

```bash
# 1. 检查状态
systemctl status cloudera-scm-server

# 2. 重置失败状态
systemctl reset-failed

# 3. 查看日志
tail -100 /var/log/cloudera-scm-server/cloudera-scm-server.log

# 4. 重新启动
systemctl start cloudera-scm-server
```

### 端口被占用

```bash
# 1. 查看占用进程
lsof -i:7180

# 2. 杀掉进程
kill -9 <PID>

# 3. 或强制清理
make force-stop
```

### 残留进程

```bash
# 1. 查看进程
ps aux | grep cloudera | grep -v grep

# 2. 强制清理
make force-stop

# 3. 或手动清理
pkill -9 -f cloudera
```

### 节点连接失败

```bash
# 1. 检查连通性
ping node02
ping node03

# 2. 测试 SSH
ssh node02 hostname
ssh node03 hostname

# 3. 测试 Ansible
ansible all_node -i /root/setup_cdh_cluster/ansible/node_group/hosts -m ping
```

### 磁盘空间不足

```bash
# 1. 检查磁盘
df -h

# 2. 清理临时文件
make clean

# 3. 清理复制文件
make cleanup-copies

# 4. 查找大文件
du -sh /opt/* | sort -h | tail -10
```

---

## 🔄 典型操作流程

### 每天启动

```bash
1. ping node02 && ping node03           # 确认节点在线
2. make start                            # 启动服务
3. make health                           # 健康检查
4. firefox http://node01:7180            # 打开 Web UI
```

### 每天停止

```bash
1. # 在 Web UI 停止所有集群服务
2. make stop                             # 停止 CDH 服务
3. make status                           # 验证停止
```

### 故障重启

```bash
1. make health                           # 检查问题
2. make logs                             # 查看日志
3. make force-stop                       # 强制停止
4. sleep 10                              # 等待10秒
5. make start                            # 重新启动
6. make health                           # 验证恢复
```

### 完整重新部署

```bash
1. ./scripts/drop_all.sh --backup       # 清理并备份
2. make full-deploy                      # 完整部署
3. make health                           # 验证部署
```

---

## 💾 备份与恢复

### 备份

```bash
# 备份配置
tar czf cdh-config-$(date +%Y%m%d).tar.gz \
  /etc/cloudera-scm-server \
  /etc/cloudera-scm-agent \
  /etc/my.cnf

# 备份数据库
mysqldump -u root -p --all-databases > cdh-db-$(date +%Y%m%d).sql
```

### 恢复

```bash
# 恢复配置
tar xzf cdh-config-YYYYMMDD.tar.gz -C /

# 恢复数据库
mysql -u root -p < cdh-db-YYYYMMDD.sql
```

---

## 📞 快速联系

- **项目位置**: `/root/setup_cdh_cluster`
- **日志文件**: `/var/log/cdh_deploy.log`
- **Web UI**: `http://node01:7180`
- **文档**: `README.md`, `OPERATIONS_GUIDE.md`

---

**保存此文件便于快速查询！**

**文档版本**: v2.0 | **更新日期**: 2025-11-11 | **作者**: RaynLiu
