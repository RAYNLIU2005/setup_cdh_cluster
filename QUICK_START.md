# ⚡ 快速开始 - 10分钟部署 CDH 集群

**作者**：RaynLiu  
**邮箱**：liuyu1_j6go@stu.cqie.edu.cn

---

## 🎯 准备工作（5分钟）

### 1️⃣ 下载虚拟机

**百度网盘：**
```
链接: https://pan.baidu.com/s/1SJUKskiSnO4sIIKNg0Ujjw?pwd=4fds
提取码: 4fds
```

### 2️⃣ 配置虚拟机

- **推荐配置**：4核CPU + 4GB内存
- **导入** 3个虚拟机到 VirtualBox/VMware
- **启动** 所有节点

### 3️⃣ 准备安装包

**下载安装包（百度网盘）：**
```
链接: https://pan.baidu.com/s/1nbhiVhN0GWYUo9JmHgC4Pg
提取码: ax3w
```

**在每个节点执行：**
```bash
mkdir -p /opt/base_file
cd /opt/base_file
# 上传并解压安装包
unzip cdh_packages.zip
rm -f cdh_packages.zip
```

---

## 🚀 部署流程（5分钟）

### 方式 1：一键部署（推荐）⭐

```bash
# 1. 进入项目目录
cd /root/setup_cdh_cluster

# 2. 初始化环境（交互式）
make init

# 3. 一键部署
make deploy

# 4. 等待完成（约5分钟）
# 部署完成后会显示访问地址
```

### 方式 2：分步部署

```bash
# 1. 检查环境
make check-env

# 2. 准备环境
make prepare-env

# 3. 部署集群
make deploy

# 4. 验证部署
make verify
```

---

## 🌐 访问 Web 界面

部署完成后，等待 **1-2 分钟** 让服务启动：

```
URL:  http://192.168.56.151:7180
或:   http://node01:7180

用户名: admin
密码:   admin
```

---

## 🔧 遇到问题？

### 一键修复所有问题

```bash
make fix-all
```

### 常见问题

**1. CM 界面只显示 1 个节点？**
```bash
make fix-agent
```

**2. Parcel 分发失败？**
```bash
make distribute-parcel
```

**3. 服务无法启动？**
```bash
make restart
```

---

## ✅ 验证部署

```bash
# 查看服务状态
make status

# 检查节点
make check-nodes

# 健康检查
make health-check-v2
```

---

## 📋 常用命令

| 命令 | 功能 |
|------|------|
| `make start` | 启动集群 |
| `make stop` | 停止集群 |
| `make restart` | 重启集群 |
| `make status` | 查看状态 |
| `make fix-all` | 修复所有问题 |
| `make help` | 查看所有命令 |

---

## 🎉 部署完成！

现在可以：
1. 访问 CM 界面
2. 添加集群（Add Cluster）
3. 选择服务（HDFS、YARN、Hive等）
4. 开始使用 Hadoop！

---

## 📚 更多文档

- [完整 README](README.md)
- [集群启停指南](doc/集群启停指南.md)
- [项目修复总结](doc/项目修复总结.md)
- [修复快速参考](FIXES_QUICK_REFERENCE.md)

---

**作者**：RaynLiu  
**版权**：保留所有权利 All Rights Reserved
