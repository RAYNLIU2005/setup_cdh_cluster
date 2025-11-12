# 🚨 节点缺失快速修复

**问题**：CM 界面只显示 1 个节点（node01），缺少 node02 和 node03

---

## ⚡ 快速修复（3 分钟）

### 在服务器上执行

```bash
cd /root/setup_cdh_cluster

# 1. 检查节点状态
make check-nodes

# 2. 自动添加缺失的节点
make add-nodes
#    提示时输入 'yes' 确认

# 3. 等待 1-2 分钟，然后刷新 CM 界面
#    访问：http://node01:7180
#    导航到：Hosts > All Hosts
#    应该看到 3 个节点
```

---

## 📋 详细步骤

### 步骤 1：检查节点状态

```bash
make check-nodes
```

**检查项目**：
- ✅ /etc/hosts 配置
- ✅ 网络连通性
- ✅ SSH 免密登录
- ✅ CM Agent 状态

### 步骤 2：添加节点

```bash
make add-nodes
```

**自动完成**：
1. 安装 Java
2. 安装 CM Agent
3. 配置 Agent
4. 启动 Agent

### 步骤 3：验证

```bash
# 检查 Agent 状态
ssh node02 'systemctl status cloudera-scm-agent'
ssh node03 'systemctl status cloudera-scm-agent'

# 应该看到 "active (running)"
```

### 步骤 4：在 CM 界面确认

1. 打开浏览器访问：`http://node01:7180`
2. 点击 **Hosts** > **All Hosts**
3. 应该看到 3 个主机

---

## ❓ 如果失败

### SSH 连接失败

```bash
# 配置 SSH 免密登录
make setup-ssh

# 测试
make test-ssh
```

### Agent 无法启动

```bash
# 手动启动
ssh node02 'sudo systemctl start cloudera-scm-agent'
ssh node03 'sudo systemctl start cloudera-scm-agent'

# 查看日志
ssh node02 'sudo tail -100 /var/log/cloudera-scm-agent/cloudera-scm-agent.log'
```

### 网络不通

```bash
# 检查 /etc/hosts
cat /etc/hosts | grep node

# 应该包含：
# 192.168.56.151 node01
# 192.168.56.152 node02
# 192.168.56.153 node03

# 测试连通性
ping -c 3 node02
ping -c 3 node03
```

---

## 📞 获取帮助

- **详细文档**：[doc/添加节点指南.md](doc/添加节点指南.md)
- **邮箱**：liuyu1_j6go@stu.cqie.edu.cn

---

**快速命令**：
```bash
make check-nodes  # 检查
make add-nodes    # 添加
```
