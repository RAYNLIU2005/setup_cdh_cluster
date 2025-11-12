# base_file 目录准备指南

**作者**：RaynLiu  
**邮箱**：liuyu1_j6go@stu.cqie.edu.cn  
**日期**：2025-11-12

---

## 一、目录位置

**在 node01（主节点）上创建**：
```bash
/opt/base_file/
```

## 二、创建目录

```bash
# 在 node01 节点执行
mkdir -p /opt/base_file/packages
mkdir -p /opt/base_file/parcels

# 设置权限
chmod 755 /opt/base_file
chmod 755 /opt/base_file/packages
chmod 755 /opt/base_file/parcels
```

## 三、目录结构

```
/opt/base_file/
├── packages/          # 安装包目录
│   ├── cloudera-manager-*.rpm
│   ├── jdk-*.tar.gz
│   ├── scala-*.tgz
│   ├── mysql-*.rpm
│   └── ... (其他安装包)
└── parcels/           # Parcel文件目录
    ├── CDH-6.2.0-*.parcel
    └── CDH-6.2.0-*.parcel.sha
```

## 四、需要的文件

### packages/ 目录文件（22个）

**Cloudera Manager 相关**：
1. `cloudera-manager-agent-6.2.0-968826.el7.x86_64.rpm`
2. `cloudera-manager-daemons-6.2.0-968826.el7.x86_64.rpm`
3. `cloudera-manager-server-6.2.0-968826.el7.x86_64.rpm`
4. `cloudera-manager-server-db-2-6.2.0-968826.el7.x86_64.rpm`
5. `enterprise-debuginfo-6.2.0-968826.el7.x86_64.rpm`

**JDK**：
6. `jdk-8u261-linux-x64.tar.gz`

**MySQL 相关**（5个RPM）：
7. `mysql-community-client-5.7.30-1.el7.x86_64.rpm`
8. `mysql-community-common-5.7.30-1.el7.x86_64.rpm`
9. `mysql-community-libs-5.7.30-1.el7.x86_64.rpm`
10. `mysql-community-libs-compat-5.7.30-1.el7.x86_64.rpm`
11. `mysql-community-server-5.7.30-1.el7.x86_64.rpm`

**MySQL JDBC驱动**：
12. `mysql-connector-java-5.1.48.jar`

**Python 3**：
13. `Python-3.8.0.tgz`

**Scala**：
14. `scala-2.13.0-M4.tgz`

**其他**：
15. `allkeys.list`
16. `cloudera-cdh-6-latest.repo`
17. `cloudera-manager.repo`
18. `openJDK8.tar.gz`
19. `repodata.tar.gz`
20. `RPM-GPG-KEY-cloudera`

### parcels/ 目录文件（2个）

1. `CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel`（约2.3GB）
2. `CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel.sha`

## 五、文件上传方式

### 方式1：使用 scp

```bash
# 在本地机器上执行
# 上传 packages 目录
scp -r /path/to/local/packages/* root@node01:/opt/base_file/packages/

# 上传 parcels 目录
scp -r /path/to/local/parcels/* root@node01:/opt/base_file/parcels/
```

### 方式2：使用 FTP/SFTP

使用 FileZilla、WinSCP 等工具上传到：
- `/opt/base_file/packages/`
- `/opt/base_file/parcels/`

### 方式3：使用挂载共享目录

```bash
# 如果使用 NFS 或 Samba
mount -t nfs server:/share /mnt
cp -r /mnt/packages/* /opt/base_file/packages/
cp -r /mnt/parcels/* /opt/base_file/parcels/
```

## 六、验证文件

### 检查目录结构

```bash
# 检查目录是否存在
ls -ld /opt/base_file
ls -ld /opt/base_file/packages
ls -ld /opt/base_file/parcels

# 查看文件数量
echo "packages 文件数: $(ls -1 /opt/base_file/packages | wc -l)"
echo "parcels 文件数: $(ls -1 /opt/base_file/parcels | wc -l)"

# 查看目录大小
du -sh /opt/base_file/packages
du -sh /opt/base_file/parcels
```

### 使用项目自带检查脚本

```bash
cd /root/setup_cdh_cluster

# 运行环境准备检查
bash scripts/prepare_environment.sh

# 或使用 Makefile
make check
```

### 手动验证关键文件

```bash
# 检查 JDK
ls -lh /opt/base_file/packages/jdk-8u261-linux-x64.tar.gz

# 检查 Cloudera Manager
ls -lh /opt/base_file/packages/cloudera-manager-server-*.rpm

# 检查 MySQL
ls -lh /opt/base_file/packages/mysql-community-*.rpm

# 检查 CDH Parcel（最大的文件，约2.3GB）
ls -lh /opt/base_file/parcels/CDH-6.2.0-*.parcel
```

## 七、权限设置

```bash
# 设置目录权限
chmod 755 /opt/base_file
chmod 755 /opt/base_file/packages
chmod 755 /opt/base_file/parcels

# 设置文件权限
chmod 644 /opt/base_file/packages/*
chmod 644 /opt/base_file/parcels/*

# 设置所有者
chown -R root:root /opt/base_file
```

## 八、配置文件中的路径

### .env 配置

在项目根目录的 `.env` 文件中配置：

```bash
# 基础文件路径
BASE_FILE_PATH=/opt/base_file
```

### Ansible 变量

在 `ansible/deploy_cdh.yml` 中已配置：

```yaml
vars:
  paths:
    base_file: /opt/base_file
    package: /opt/setup_cdh
```

## 九、常见问题

### Q1: 目录位置可以修改吗？

**A**: 可以，但需要同步修改以下位置：
1. `.env` 文件中的 `BASE_FILE_PATH`
2. `ansible/deploy_cdh.yml` 中的 `paths.base_file`
3. 各个 Ansible 组件脚本中的路径引用

**不建议修改**，使用默认路径 `/opt/base_file` 最简单。

### Q2: 文件必须放在主节点吗？

**A**: 是的，必须放在 **node01（主节点）** 上，因为：
- Ansible 从主节点分发文件到其他节点
- 主节点需要建立本地 YUM 仓库
- Cloudera Manager Server 需要访问 Parcel 文件

### Q3: 需要在从节点创建吗？

**A**: **不需要**，只在主节点创建即可。部署过程中会自动：
- 从主节点分发必需文件到从节点
- 在从节点创建 `/opt/setup_cdh` 目录
- 通过软链接或复制方式部署

### Q4: 磁盘空间需要多大？

**A**: 至少需要 **8GB** 可用空间：
- packages 目录：约 3-4GB
- parcels 目录：约 2.3GB
- 预留缓冲空间：2GB

检查磁盘空间：
```bash
df -h /opt
```

### Q5: 如何获取这些安装包？

**A**: 

1. **Cloudera Manager 和 CDH Parcel**：
   - 官方下载：https://archive.cloudera.com/cm6/6.2.0/
   - CDH Parcel：https://archive.cloudera.com/cdh6/6.2.0/parcels/

2. **JDK**：
   - Oracle 官网：https://www.oracle.com/java/technologies/javase-downloads.html
   - 或使用 OpenJDK

3. **MySQL**：
   - MySQL 官网：https://dev.mysql.com/downloads/mysql/5.7.html
   - 下载 el7 版本的 RPM Bundle

4. **其他组件**：
   - Python 3：https://www.python.org/downloads/
   - Scala：https://www.scala-lang.org/download/

### Q6: 部署后可以删除吗？

**A**: **不能删除！**

项目使用软链接方式优化磁盘空间，多个位置指向 `/opt/base_file/`：
- `/opt/setup_cdh/` → 软链接到 packages
- `/opt/cloudera/parcel-repo/` → 软链接到 parcels

删除源文件会导致服务无法正常运行。

### Q7: 如何清理和重新上传？

```bash
# 备份现有文件（可选）
mv /opt/base_file /opt/base_file.bak

# 重新创建
mkdir -p /opt/base_file/{packages,parcels}

# 上传新文件
# ... 使用 scp 或其他方式上传

# 验证
ls -lh /opt/base_file/packages
ls -lh /opt/base_file/parcels

# 确认无误后删除备份
rm -rf /opt/base_file.bak
```

## 十、完整检查清单

部署前请确认：

- [ ] 已在 node01 创建 `/opt/base_file` 目录
- [ ] 已创建 `packages` 和 `parcels` 子目录
- [ ] packages 目录包含所有 22 个文件
- [ ] parcels 目录包含 2 个文件（.parcel 和 .parcel.sha）
- [ ] 目录权限设置为 755
- [ ] 文件权限设置为 644
- [ ] 所有者为 root:root
- [ ] 磁盘可用空间 >= 8GB
- [ ] 已运行检查脚本验证

## 十一、快速验证命令

```bash
#!/bin/bash
# 快速验证脚本

echo "=========================================="
echo "base_file 目录验证"
echo "=========================================="

# 检查目录
echo -e "\n1. 检查目录结构..."
if [ -d "/opt/base_file" ]; then
    echo "✓ /opt/base_file 存在"
else
    echo "✗ /opt/base_file 不存在"
    exit 1
fi

if [ -d "/opt/base_file/packages" ]; then
    echo "✓ packages 子目录存在"
else
    echo "✗ packages 子目录不存在"
fi

if [ -d "/opt/base_file/parcels" ]; then
    echo "✓ parcels 子目录存在"
else
    echo "✗ parcels 子目录不存在"
fi

# 检查文件数量
echo -e "\n2. 检查文件数量..."
PKG_COUNT=$(ls -1 /opt/base_file/packages 2>/dev/null | wc -l)
PARCEL_COUNT=$(ls -1 /opt/base_file/parcels 2>/dev/null | wc -l)

echo "packages: $PKG_COUNT 个文件（期望 20-22 个）"
echo "parcels: $PARCEL_COUNT 个文件（期望 2 个）"

# 检查大小
echo -e "\n3. 检查目录大小..."
du -sh /opt/base_file/packages 2>/dev/null
du -sh /opt/base_file/parcels 2>/dev/null

# 检查关键文件
echo -e "\n4. 检查关键文件..."
KEY_FILES=(
    "jdk-8u261-linux-x64.tar.gz"
    "cloudera-manager-server-6.2.0-968826.el7.x86_64.rpm"
    "mysql-community-server-5.7.30-1.el7.x86_64.rpm"
)

for file in "${KEY_FILES[@]}"; do
    if [ -f "/opt/base_file/packages/$file" ]; then
        echo "✓ $file"
    else
        echo "✗ $file 不存在"
    fi
done

# 检查 Parcel
if ls /opt/base_file/parcels/CDH-6.*.parcel &>/dev/null; then
    echo "✓ CDH Parcel 文件"
else
    echo "✗ CDH Parcel 文件不存在"
fi

if ls /opt/base_file/parcels/CDH-6.*.parcel.sha &>/dev/null; then
    echo "✓ CDH Parcel SHA 文件"
else
    echo "✗ CDH Parcel SHA 文件不存在"
fi

# 检查磁盘空间
echo -e "\n5. 检查磁盘空间..."
df -h /opt | grep -v Filesystem

echo -e "\n=========================================="
echo "验证完成"
echo "=========================================="
```

保存为 `check_base_file.sh` 并运行：
```bash
chmod +x check_base_file.sh
./check_base_file.sh
```

---

## 总结

`/opt/base_file/` 目录是项目的**核心依赖**，必须在部署前正确准备：

1. **位置**：node01 的 `/opt/base_file/`
2. **结构**：packages/ 和 parcels/ 两个子目录
3. **内容**：所有安装包和 Parcel 文件
4. **权限**：755 目录，644 文件，root 所有
5. **空间**：至少 8GB 可用空间

准备完成后，使用 `make check` 或 `make test-env` 验证环境是否就绪。

---

**作者**：RaynLiu  
**邮箱**：liuyu1_j6go@stu.cqie.edu.cn  
**日期**：2025-11-12
