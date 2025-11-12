# CDH 多节点集群管理指南

**完整的三节点集群管理 | Copyright © 2025 RaynLiu**

---

## 📋 集群架构

```
node01 (Master 节点)
├─ MySQL Server ✓
├─ httpd ✓
├─ Cloudera Manager Server ✓
└─ Cloudera Manager Agent ✓

node02 (Slave 节点)
└─ Cloudera Manager Agent ✓

node03 (Slave 节点)
└─ Cloudera Manager Agent ✓
```

---

## 🚀 快速启动多节点集群

### 完整流程（推荐）

```bash
cd /root/setup_cdh_cluster

# 1. 确保所有虚拟机已启动
# 在 VirtualBox/VMware 中启动 node01, node02, node03

# 2. 检查节点连通性
make nodes

# 3. 启动所有节点
make start-all
```

---

## 🎯 多节点管理命令

### 1. 检查所有节点连通性

```bash
make nodes
```

**输出示例**：
```
==========================================
  节点连通性检查
==========================================

检查 node01 ... ✓ 在线 (SSH 可连接)
检查 node02 ... ✓ 在线 (SSH 可连接)
检查 node03 ... ✓ 在线 (SSH 可连接)

==========================================
  ✓ 所有节点在线
==========================================
```

**如果节点离线**：
```
检查 node02 ... ✗ 离线或不可达
检查 node03 ... ✗ 离线或不可达

==========================================
  ⚠ 部分节点离线

  提示：
  - 请确保所有虚拟机已启动
  - 检查网络连接
  - 验证 SSH 服务运行正常
==========================================
```

---

### 2. 启动所有节点

```bash
make start-all
```

**执行步骤**：
```
==========================================
  步骤 1/3: 检查节点连通性
==========================================
检查 node01 ... ✓ 在线 (SSH 可连接)
检查 node02 ... ✓ 在线 (SSH 可连接)
检查 node03 ... ✓ 在线 (SSH 可连接)

==========================================
  步骤 2/3: 启动 Master 节点服务
==========================================
[INFO] 启动master节点服务...
[INFO] 等待CM Server启动（约30秒）...
[INFO] 启动所有节点CM Agent...

==========================================
  步骤 3/3: 检查 Slave 节点状态
==========================================
检查 node02 Agent ... ✓ 运行中
检查 node03 Agent ... ✓ 运行中

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

---

### 3. 停止所有节点

```bash
make stop-all
```

**输出示例**：
```
==========================================
  停止所有节点
==========================================
[INFO] 停止所有节点CM Agent...
[INFO] 停止master节点服务...
[INFO] 清理残留进程...
[INFO] 重置服务状态...

==========================================
  停止完成汇总
==========================================
  node01 Agent: ✓ 已停止
  node02 Agent: ✓ 已停止
  node03 Agent: ✓ 已停止

  已停止节点: 3/3
==========================================
```

---

## 📊 对比：单节点 vs 多节点命令

| 操作 | 单节点命令 | 多节点命令 | 说明 |
|---|---|---|---|
| **检查连通性** | - | `make nodes` | 检查所有节点 |
| **启动服务** | `make start` | `make start-all` | 含连通性检查和汇总 |
| **停止服务** | `make stop` | `make stop-all` | 含状态汇总 |
| **查看状态** | `make status` | `make status` | 相同 |
| **健康检查** | `make health` | `make health` | 自动检测所有在线节点 |

---

## 🔄 典型操作场景

### 场景 1: 每天启动集群

```bash
# 1. 启动所有虚拟机（在宿主机中操作）
# VirtualBox: 启动 node01, node02, node03
# VMware: 启动三个虚拟机

# 2. 等待1-2分钟，让虚拟机完全启动

# 3. SSH 到 node01
ssh root@node01

# 4. 进入项目目录
cd /root/setup_cdh_cluster

# 5. 检查节点连通性
make nodes

# 6. 启动所有节点
make start-all

# 7. 验证集群健康
make health

# 8. 访问 Web UI
firefox http://node01:7180
```

---

### 场景 2: 每天停止集群

```bash
# 1. SSH 到 node01
ssh root@node01

# 2. 进入项目目录
cd /root/setup_cdh_cluster

# 3. 停止所有节点
make stop-all

# 4. 验证停止
make status

# 5. 关闭虚拟机（在宿主机中操作）
# VirtualBox: 正常关机 node01, node02, node03
# VMware: Shut Down Guest
```

---

### 场景 3: 部分节点故障

```bash
# 1. 检查节点连通性
make nodes

# 输出：
# 检查 node01 ... ✓ 在线
# 检查 node02 ... ✗ 离线
# 检查 node03 ... ✓ 在线

# 2. 查看健康状态
make health

# 3. 手动启动 node02
# 在宿主机启动 node02 虚拟机

# 4. 等待 node02 启动完成
ping node02

# 5. 启动 node02 上的 Agent
ssh node02 "systemctl start cloudera-scm-agent"

# 6. 验证
make nodes
make health
```

---

### 场景 4: 新增节点到集群

```bash
# 1. 确保新节点已部署
make nodes

# 2. 在新节点上安装 Agent（如果尚未安装）
ssh node04 "systemctl start cloudera-scm-agent"

# 3. 在 CM Web UI 中添加主机
# 访问 http://node01:7180
# Hosts -> Add Hosts

# 4. 验证新节点
make health
```

---

## 🛠️ 故障排查

### 问题 1: 节点检查失败

```bash
make nodes
# 输出: 检查 node02 ... ✗ 离线或不可达
```

**排查步骤**：

```bash
# 1. 检查虚拟机是否启动
# 在宿主机上检查 VirtualBox/VMware

# 2. 测试网络连通性
ping node02

# 3. 测试 SSH 连接
ssh node02 "hostname"

# 4. 检查 SSH 服务
ssh node02 "systemctl status sshd"

# 5. 检查网络配置
ssh node02 "ip addr show"
```

---

### 问题 2: Agent 启动失败

```bash
make start-all
# 输出: 检查 node02 Agent ... ⚠ 未运行或不可达
```

**排查步骤**：

```bash
# 1. 手动检查 Agent 状态
ssh node02 "systemctl status cloudera-scm-agent"

# 2. 查看 Agent 日志
ssh node02 "tail -100 /var/log/cloudera-scm-agent/cloudera-scm-agent.log"

# 3. 检查配置文件
ssh node02 "cat /etc/cloudera-scm-agent/config.ini | grep server_host"

# 4. 手动启动 Agent
ssh node02 "systemctl start cloudera-scm-agent"

# 5. 验证端口连接
ssh node02 "telnet node01 7182"
```

---

### 问题 3: 停止后有残留进程

```bash
make stop-all
# 输出: node02 Agent: ⚠ 仍在运行
```

**解决方案**：

```bash
# 1. 使用强制停止
make force-stop

# 2. 手动清理特定节点
ssh node02 "pgrep -f cloudera | xargs kill -9"
ssh node02 "systemctl reset-failed"

# 3. 验证清理结果
make ps
```

---

## 📊 节点状态监控

### 实时监控所有节点

创建监控脚本：

```bash
cat > /tmp/monitor_nodes.sh << 'EOF'
#!/bin/bash

while true; do
    clear
    echo "=========================================="
    echo "  CDH 集群节点监控"
    echo "  $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=========================================="
    echo ""
    
    for node in node01 node02 node03; do
        echo "=== $node ==="
        if ping -c 1 -W 1 $node >/dev/null 2>&1; then
            echo "  网络: ✓ 在线"
            
            # SSH 连接
            if ssh -o ConnectTimeout=2 $node "hostname" >/dev/null 2>&1; then
                echo "  SSH:  ✓ 可连接"
                
                # Agent 状态
                if ssh $node "systemctl is-active cloudera-scm-agent" 2>/dev/null | grep -q active; then
                    echo "  Agent: ✓ 运行中"
                else
                    echo "  Agent: ✗ 未运行"
                fi
                
                # 进程数
                pcount=$(ssh $node "ps aux | grep -E '[c]loudera' | wc -l" 2>/dev/null)
                echo "  进程: $pcount"
            else
                echo "  SSH:  ✗ 不可达"
            fi
        else
            echo "  网络: ✗ 离线"
        fi
        echo ""
    done
    
    echo "按 Ctrl+C 退出监控"
    sleep 5
done
EOF

chmod +x /tmp/monitor_nodes.sh
/tmp/monitor_nodes.sh
```

---

## 🔧 高级配置

### 批量操作所有节点

```bash
# 在所有节点上执行命令
ansible all_node -i /root/setup_cdh_cluster/ansible/node_group/hosts \
  -m shell -a "your_command"

# 示例：检查所有节点磁盘空间
ansible all_node -i /root/setup_cdh_cluster/ansible/node_group/hosts \
  -m shell -a "df -h /"

# 示例：重启所有节点的 Agent
ansible all_node -i /root/setup_cdh_cluster/ansible/node_group/hosts \
  -m service -a "name=cloudera-scm-agent state=restarted"
```

---

### 配置节点自动启动

```bash
# 在所有节点上设置 Agent 开机自启
ansible all_node -i /root/setup_cdh_cluster/ansible/node_group/hosts \
  -m service -a "name=cloudera-scm-agent enabled=yes"

# 在 Master 节点设置服务开机自启
ssh node01 "
systemctl enable cloudera-scm-server
systemctl enable mysqld
systemctl enable httpd
"
```

---

## 📝 最佳实践

### 1. 启动顺序

✅ **推荐顺序**：
```bash
1. 启动所有虚拟机
2. 等待网络稳定（1-2分钟）
3. 执行 make nodes 检查连通性
4. 执行 make start-all 启动服务
5. 执行 make health 验证健康
```

❌ **避免**：
- 不要在节点未完全启动时执行启动命令
- 不要跳过连通性检查
- 不要忽略健康检查结果

---

### 2. 停止顺序

✅ **推荐顺序**：
```bash
1. 在 Web UI 中停止所有集群服务
2. 执行 make stop-all 停止 CDH 服务
3. 执行 make status 验证停止
4. 正常关闭虚拟机
```

❌ **避免**：
- 不要强制关闭虚拟机电源
- 不要在服务运行时强制关机
- 不要跳过停止验证

---

### 3. 日常维护

**每天操作**：
```bash
make nodes          # 检查节点
make start-all      # 启动集群
make health         # 健康检查
```

**每周操作**：
```bash
make logs           # 检查日志
make ps             # 检查进程
make ports          # 检查端口
```

**每月操作**：
```bash
make clean          # 清理临时文件
make check          # 检查磁盘空间
```

---

## 🎯 快速参考

### 核心命令

| 命令 | 用途 | 使用场景 |
|---|---|---|
| `make nodes` | 检查连通性 | 启动前必查 |
| `make start-all` | 启动所有节点 | 每天启动 |
| `make stop-all` | 停止所有节点 | 每天停止 |
| `make health` | 健康检查 | 启动后验证 |
| `make status` | 查看状态 | 随时查看 |

### 故障处理命令

| 命令 | 用途 |
|---|---|
| `make force-stop` | 强制停止清理 |
| `make ps` | 查看进程 |
| `make ports` | 查看端口 |
| `make logs` | 查看日志 |

---

## 📞 获取帮助

```bash
# 查看所有命令
make help

# 查看脚本帮助
./scripts/manage_cluster.sh help

# 查看文档
cat OPERATIONS_GUIDE.md
cat QUICK_REFERENCE.md
```

---

**文档版本**: v2.0  
**适用场景**: 三节点 CDH 集群  
**最后更新**: 2025-11-11  
**作者**: RaynLiu
