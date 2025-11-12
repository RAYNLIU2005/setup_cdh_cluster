# CDH 集群部署优化说明

**Copyright © 2025 RaynLiu - 保留所有权利 All Rights Reserved**

---

## 优化概述

本优化方案通过使用**软链接替代文件复制**，显著减少磁盘空间占用，提升部署效率。

### 优化前后对比

| 项目 | 优化前 | 优化后 | 节省空间 |
|---|---|---|---|
| 安装包分发 | 复制文件 | 软链接 | ~800MB × 节点数 |
| Parcel 文件 | 复制目录 | 软链接 | ~2-4GB |
| MySQL RPM | 复制文件 | 软链接 | ~700MB × 节点数 |
| CM RPM | 复制文件 | 软链接 | ~200MB × 节点数 |
| **总计（3节点）** | **~6-8GB** | **0GB** | **节省 6-8GB** |

---

## 优化内容

### 1. 版权信息保护

所有命令执行时显示版权信息：
```
==========================================
  CDH集群部署管理系统
  Copyright © 2025 RaynLiu
  保留所有权利 All Rights Reserved
==========================================
```

### 2. 文件分发优化

**优化位置**: `ansible/component/setup_system_env.yml`

**原方案**: 
```yaml
copy:
  src: '/opt/base_file/packages/{{ item }}'
  dest: '/opt/setup_cdh/{{ item }}'
```

**优化方案**:
```yaml
file:
  src: '/opt/base_file/packages/{{ item }}'
  dest: '/opt/setup_cdh/{{ item }}'
  state: link
  force: yes
```

**优点**:
- ✅ 节省磁盘空间：每个节点节省约 1.5-2GB
- ✅ 加快部署速度：创建链接比复制文件快 10-100 倍
- ✅ 统一管理：只需在源目录更新文件

### 3. Parcel 文件优化

**优化位置**: `ansible/component/setup_cloudera_manager_master.yml`

**原方案**: 复制整个 parcels 目录（2-4GB）

**优化方案**: 创建软链接
```yaml
file:
  src: '/opt/base_file/parcels'
  dest: '/opt/cloudera/parcel-repo'
  state: link
```

**优点**:
- ✅ 节省 2-4GB 磁盘空间
- ✅ 避免重复存储
- ✅ 简化更新流程

### 4. 清理工具

**新增命令**: `make cleanup-copies`

**功能**:
1. 自动检测并删除已复制的文件
2. 将 parcel-repo 目录转换为软链接
3. 显示清理前后的磁盘使用情况
4. 不影响正在运行的服务

---

## 使用方法

### 新部署（推荐）

使用优化后的脚本进行全新部署：

```bash
cd /root/setup_cdh_cluster

# 查看帮助（显示版权信息）
make help

# 完整部署流程
make full-deploy
```

新部署会自动使用软链接，无需额外操作。

### 已有集群优化

对于已部署的集群，可以运行清理命令：

```bash
# 清理复制文件，释放磁盘空间
make cleanup-copies

# 或使用脚本直接调用
./scripts/manage_cluster.sh cleanup
```

**注意**: 此操作会短暂重启 CM Server（约 30 秒），请在业务低峰期执行。

---

## 清理详情

执行 `make cleanup-copies` 时的操作流程：

### 步骤 1: 清理各节点复制文件

```bash
# 在所有节点执行
cd /opt/setup_cdh
for file in *; do
    if [ -e $file ] && [ ! -L $file ]; then
        rm -f $file  # 删除非软链接的文件
    fi
done
```

### 步骤 2: 优化 Parcel 存储

```bash
# 在 node01 执行
systemctl stop cloudera-scm-server
mv /opt/cloudera/parcel-repo /opt/cloudera/parcel-repo.bak
ln -s /opt/base_file/parcels /opt/cloudera/parcel-repo
systemctl start cloudera-scm-server
```

### 步骤 3: 验证效果

```bash
# 检查磁盘使用情况
make check

# 检查服务状态
make status
```

---

## 安全性说明

### 软链接的优势

1. **透明性**: 应用程序无感知，访问链接等同于访问文件
2. **原子性**: 创建链接是原子操作，不会出现中间状态
3. **可靠性**: 源文件损坏才会影响链接，反之亦然

### 注意事项

⚠️ **重要**:
1. 不要删除 `/opt/base_file/` 目录中的源文件
2. 确保 `/opt/base_file/` 目录权限正确（755）
3. 如果需要移动源文件，需要重新创建链接

### 回退方案

如果需要恢复为复制方式：

```bash
# 删除软链接
rm -f /opt/setup_cdh/*

# 重新复制文件
cp /opt/base_file/packages/* /opt/setup_cdh/

# 恢复 parcel-repo
rm -f /opt/cloudera/parcel-repo
cp -r /opt/cloudera/parcel-repo.bak /opt/cloudera/parcel-repo
```

---

## 故障排查

### 问题 1: "No such file or directory"

**原因**: 源文件被删除或移动

**解决**:
```bash
# 检查源文件是否存在
ls -l /opt/base_file/packages/

# 重新创建链接
ln -sf /opt/base_file/packages/文件名 /opt/setup_cdh/文件名
```

### 问题 2: 权限问题

**原因**: 链接或源文件权限不正确

**解决**:
```bash
# 修复权限
chmod 755 /opt/base_file/packages/*
chown root:root /opt/base_file/packages/*
```

### 问题 3: Parcel 加载失败

**原因**: parcel-repo 链接有问题

**解决**:
```bash
# 检查链接
ls -l /opt/cloudera/parcel-repo

# 重新创建链接
rm -f /opt/cloudera/parcel-repo
ln -s /opt/base_file/parcels /opt/cloudera/parcel-repo
chown -h cloudera-scm:cloudera-scm /opt/cloudera/parcel-repo
systemctl restart cloudera-scm-server
```

---

## 命令速查表

```bash
# 查看帮助（带版权信息）
make help

# 检查磁盘空间
make check

# 清理临时文件
make clean

# 清理复制文件，释放空间
make cleanup-copies

# 查看服务状态
make status

# 完整部署（新环境）
make full-deploy
```

---

## 技术支持

**项目作者**: RaynLiu  
**创建日期**: 2025-11-11  
**版本**: v2.0 (优化版)

**Copyright © 2025 RaynLiu - 保留所有权利 All Rights Reserved**

---

## 更新日志

### v2.0 (2025-11-11)
- ✅ 添加版权信息保护
- ✅ 使用软链接替代文件复制
- ✅ 优化 Parcel 文件存储
- ✅ 添加磁盘空间清理工具
- ✅ 节省 6-8GB 磁盘空间

### v1.0 (2025-11-10)
- 初始版本
- 基础 CDH 集群部署功能
