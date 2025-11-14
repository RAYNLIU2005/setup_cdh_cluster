<div align="center">

# ☕ CDH 集群自动化部署系统

<h3>Only by one cup of coffee time<br/>You will build your CDH clusters!</h3>

[![Version](https://img.shields.io/badge/version-2.2-blue.svg)](https://github.com/RaynLiu/setup_cdh_cluster)
[![CDH](https://img.shields.io/badge/CDH-6.2.0-orange.svg)](https://www.cloudera.com/)
[![Python](https://img.shields.io/badge/python-3.8+-green.svg)](https://www.python.org/)
[![Ansible](https://img.shields.io/badge/ansible-2.8+-red.svg)](https://www.ansible.com/)
[![Inspired by](https://img.shields.io/badge/inspired%20by-playground-brightgreen.svg)](https://gitee.com/several-boats/playground.git)

**🎯 一杯咖啡的时间，搭建你的大数据集群！**

</div>

---

## 💫 这是什么？

一个**超级简单**的 CDH 6.2.0 大数据集群自动化部署工具！

不需要复杂的配置，不需要漫长的等待，**只需一个命令**就能拥有自己的 Hadoop 集群！

### ✨ 为什么选择我？

| 特性 | 说明 |
|------|------|
| ⚡ **超快速** | 30-60 分钟完成集群部署（喝杯咖啡的时间） |
| 🎯 **超简单** | `make init` + `make deploy` 两步搞定 |
| 🔑 **统一密码** | 所有密码都是 `123456`，简单好记！ |
| 🛠️ **自动修复** | 遇到问题？`make fix-all` 一键修复！ |
| 🎨 **界面美观** | 彩色输出 + Emoji，赏心悦目！ |
| 📚 **文档完善** | 每一步都有详细说明，新手友好！ |

## 🚀 快速开始（三步走）

<table>
<tr>
<td align="center" width="33%">
<h3>📥 步骤 1</h3>
<b>下载虚拟机</b><br/>
预配置好的 CentOS 7<br/>
开箱即用！
</td>
<td align="center" width="33%">
<h3>⚡ 步骤 2</h3>
<b>初始化环境</b><br/>
一个命令搞定<br/>
<code>make init</code>
</td>
<td align="center" width="33%">
<h3>🎉 步骤 3</h3>
<b>一键部署</b><br/>
喝杯咖啡等待<br/>
<code>make deploy</code>
</td>
</tr>
</table>

## 📑 目录导航

<table>
<tr>
<td>

**🎬 快速开始**
- [📥 下载虚拟机](#-下载虚拟机和安装包)
- [⚙️ 节点配置](#-集群节点信息)
- [🔑 密码说明](#-密码配置)
- [🚀 开始部署](#-详细部署步骤)

</td>
<td>

**🛠️ 进阶使用**
- [🔧 环境准备](#-环境准备手动配置)
- [💾 磁盘扩容](#-可选虚拟机磁盘扩容)
- [🌐 访问界面](#-访问-cloudera-manager)
- [🩹 故障修复](#️-一键修复工具)

</td>
<td>

**📚 更多资源**
- [❓ 常见问题](#-faq)
- [📖 完整文档](#-文档中心)
- [💡 使用技巧](#-make-命令大全)
- [🎓 项目概述](#-项目信息)

</td>
</tr>
</table>

---

## 📥 下载虚拟机和安装包

### 🎁 第一步：获取虚拟机镜像

> 💡 我们为你准备好了一切！开箱即用的 CentOS 7 虚拟机

<table>
<tr>
<td width="50%">

**📥 百度网盘下载**
```
🔗 https://pan.baidu.com/s/1SJUKskiSnO4sIIKNg0Ujjw?pwd=4fds
🔑 提取码: 4fds
```

**💻 推荐配置**
- ✅ 4核CPU + 4GB内存（流畅运行）
- ⚠️ 2核CPU + 2GB内存（最低要求）
- 💾 磁盘：20GB（可后期扩容至100GB）

</td>
<td width="50%">

**🖥️ 集群架构**

| 节点 | IP | 角色 |
|------|----|----|
| 🎯 node01 | 192.168.56.151 | Master |
| 🔧 node02 | 192.168.56.152 | Worker |
| 🔧 node03 | 192.168.56.153 | Worker |

**🔑 默认密码：`123456`**

</td>
</tr>
</table>

### 📦 第二步：下载安装包

> 🎁 CDH 所需的所有软件包（总大小 4.49 GB）

```
🔗 链接: https://pan.baidu.com/s/1nbhiVhN0GWYUo9JmHgC4Pg
🔑 提取码: ax3w
```

**📦 包含内容：**
- `packages.zip` - CDH 组件包（RPM、JDK、MySQL 等）
- `parcels.zip` - CDH Parcel 文件

### 🚀 第三步：上传并解压

**在 node01 节点执行：**

```bash
# 1️⃣ 创建目录
mkdir -p /opt/base_file
cd /opt/base_file

# 2️⃣ 上传 zip 文件（使用 WinSCP 或 rz 命令）
# 如果没有 unzip 命令，先安装
yum install -y unzip

# 3️⃣ 解压文件
unzip packages.zip
unzip parcels.zip

# 4️⃣ 删除 zip 释放空间（可选）
rm -f packages.zip parcels.zip

# 5️⃣ 验证文件
ls -lh /opt/base_file/
# 应该看到 packages/ 和 parcels/ 两个目录
```

> ✅ **完成！** 现在你已经准备好了所有需要的文件

## 版本要求

| 组件 | 版本 | 说明 |
|---|---|---|
| CDH | 6.2.0 | Hadoop 生态系统 |
| Ansible | 2.8.12+ | 自动化部署工具 |
| **Python** | **3.8+** | 推荐 Python 3.8, 3.9, 3.10 |
| CentOS | 7.x | 操作系统 | 


---

## 🚀 详细部署步骤

### 步骤 4️⃣：克隆项目

```bash
# 在 node01 上执行
cd /root
git clone https://gitee.com/sweetliuyu/setup_cdh_cluster.git
cd setup_cdh_cluster
```

### 步骤 5️⃣：环境初始化 ⭐ 必须

> 🎉 使用 **[playground](https://gitee.com/several-boats/playground.git)** 魔法工具，一键搞定所有环境配置！

```bash
# 1️⃣ 下载 playground
cd /root
git clone https://gitee.com/several-boats/playground.git
cd playground

# 2️⃣ 安装 playground
chmod +x playground.sh
./playground.sh install
source /etc/profile

# 3️⃣ 神奇的一键初始化 ✨
playground init
```

**交互提示（按回车使用默认值）：**
```
IP: 192.168.56.151 ✓
Hostname: node01 ✓
Username: root ✓
Password: 123456 ✓
...（node02、node03 同样配置）

请确认以上信息是否正确 (y/n): y
是否需要安装JDK？(yes/no): no  ⚠️ 必须选 no！
```

**🎯 Playground 会自动完成：**
- ✅ DNS 配置
- ✅ 阿里云镜像源
- ✅ SSH 免密登录（三个节点互通）
- ✅ 防火墙关闭
- ✅ SELinux 禁用
- ✅ 时间同步
- ✅ 主机名配置

> 💡 **小贴士**：整个过程约 2-3 分钟，看到"环境初始化成功！"就搞定啦！

<details>
<summary>📝 查看完整输出示例（点击展开）</summary>

```
[root@node01 ~]# playground init
IP: 192.168.56.151
Hostname: node01
Username: root
Password: 123456
...
--------------------
|   环境初始化成功！|
--------------------

将集群ip及其映射的hostname添加到/etc/hosts中
关闭防火墙、SELINUX

集群各节点之间配置SSH无密码登录
spawn ssh-copy-id node01
...
Number of key(s) added: 1
spawn ssh-copy-id node02
...
Number of key(s) added: 1
spawn ssh-copy-id node03
...
Number of key(s) added: 1

节点 node01 配置免密登录成功
跳过 JDK 安装

--------------------
|   环境初始化成功！|
--------------------

目前正在设置node01节点的系统环境
目前正在设置node02节点的系统环境
目前正在设置node03节点的系统环境
```
</details>

### 步骤 6️⃣：一键部署 🚀

> ⚡ 激动人心的时刻到了！一个命令，搞定一切！

```bash
cd /root/setup_cdh_cluster

# 方式 1：完整自动化部署（推荐新手）
make full-deploy
# 包含：环境准备 + 性能优化 + Parcel 配置 + 集群部署

# 方式 2：仅部署集群（已完成环境准备）
make deploy

# 方式 3：快速重部署（清理 + 部署）
make quick-deploy
```

**⏱️ 部署时间：**
- 环境准备：5-10 分钟
- 集群部署：20-30 分钟
- **总计：30-60 分钟（喝杯咖啡刚刚好！）**

**🎯 自动完成的任务：**
- ✅ 安装 MySQL 数据库
- ✅ 配置 Cloudera Manager Server
- ✅ 安装所有节点 Agent
- ✅ 分发 CDH Parcel 包
- ✅ 初始化所有组件数据库
- ✅ 配置服务自启动

> 💡 **提示**：部署过程中可以喝杯咖啡☕，放松一下！

### 步骤 7️⃣：访问 Cloudera Manager

**部署完成后：**

```
🎉 访问地址: http://192.168.56.151:7180
🔑 默认账号: admin
🔑 默认密码: admin
```

**🌟 接下来在 CM 界面中：**
1. 点击"添加集群"
2. 选择要安装的服务（HDFS、YARN、Hive 等）
3. 点击"继续"，等待服务安装
4. 🎊 完成！开始使用你的大数据集群！

---

## 💾 可选：虚拟机磁盘扩容

> 💾 **如果虚拟机磁盘空间不足，建议在部署 CDH 之前进行扩容（20GB → 100GB）**

**第一步：在 Windows 宿主机扩展虚拟磁盘**

```powershell
# 1. 完全关闭所有虚拟机（不是挂起）

# 2. 在 Windows PowerShell (管理员) 中执行
cd "C:\Program Files\Oracle\VirtualBox"

# 3. 查看虚拟磁盘路径
.\VBoxManage.exe list hdds

# 4. 扩容虚拟磁盘到 100GB（替换为实际路径）
.\VBoxManage.exe modifymedium disk "E:\你的路径\Node01.vdi" --resize 102400
.\VBoxManage.exe modifymedium disk "E:\你的路径\Node02.vdi" --resize 102400
.\VBoxManage.exe modifymedium disk "E:\你的路径\Node03.vdi" --resize 102400
```

**第二步：在 Linux 系统内扩展分区（一键完成所有节点）**

```bash
# 在 node01 上登录后执行以下一键脚本
cd /root/setup_cdh_cluster

# node01 扩容
chmod +x scripts/expand_partition_fdisk.sh
./scripts/expand_partition_fdisk.sh  # 输入 YES 和 yes，重启后执行：
pvresize /dev/sda2 && lvextend -l +100%FREE /dev/centos/root && xfs_growfs /

# node02 和 node03 一键扩容
scp scripts/expand_partition_fdisk.sh node02:/root/
scp scripts/expand_partition_fdisk.sh node03:/root/

ssh node02 "chmod +x /root/expand_partition_fdisk.sh && echo -e 'YES\nyes' | /root/expand_partition_fdisk.sh"
sleep 120  # 等待 node02 重启完成
ssh node02 "pvresize /dev/sda2 && lvextend -l +100%FREE /dev/centos/root && xfs_growfs / && df -h /"

ssh node03 "chmod +x /root/expand_partition_fdisk.sh && echo -e 'YES\nyes' | /root/expand_partition_fdisk.sh"
sleep 120  # 等待 node03 重启完成
ssh node03 "pvresize /dev/sda2 && lvextend -l +100%FREE /dev/centos/root && xfs_growfs / && df -h /"

# 验证所有节点
for node in node01 node02 node03; do
    echo "========== $node =========="
    ssh $node "df -h / | tail -1"
done
```

> 💡 **提示**：扩容完成后，所有节点根分区应显示约 98GB 可用空间

#### 步骤 8: 一键部署

```bash
# 开始部署 CDH 集群
make deploy

# 等待 30-60 分钟，部署会自动完成
```

#### 步骤 9: 访问管理界面

```bash
# 访问 Cloudera Manager
http://192.168.56.151:7180

# 默认账号：
# 用户名: admin
# 密码: admin
```

---

## 📋 集群节点信息

| 角色 | IP | hostname | 说明 |
| --- | --- | --- | --- |
| Master  | 192.168.56.151  | node01 | CM Server + NameNode + ResourceManager |
| Worker | 192.168.56.152 | node02 | CM Agent + DataNode + NodeManager |
| Worker | 192.168.56.153 | node03 | CM Agent + DataNode + NodeManager |

---

## 🔑 密码配置说明

> 🎯 **重要**：为了简化部署和测试，本项目所有密码统一设置为 `123456`

### 密码列表

| 类型 | 用户名 | 密码 | 说明 |
| --- | --- | --- | --- |
| **SSH 登录** | root | 123456 | 所有节点的 root 密码 |
| **MySQL Root** | root | 123456 | MySQL 数据库 root 密码 |
| **Cloudera Manager** | scm | 123456 | SCM 数据库密码 |
| **Activity Monitor** | amon | 123456 | AMON 数据库密码 |
| **Reports Manager** | rman | 123456 | RMAN 数据库密码 |
| **Hive** | hive | 123456 | Hive 数据库密码 |
| **Sentry** | sentry | 123456 | Sentry 数据库密码 |
| **Navigator** | nav | 123456 | Navigator 数据库密码 |
| **Navigator Metadata** | navms | 123456 | Navigator Metadata 数据库密码 |
| **Oozie** | oozie | 123456 | Oozie 数据库密码 |
| **Hue** | hue | 123456 | Hue 数据库密码 |

### 修改密码

如需修改密码，请编辑以下文件：

```bash
# 1. 编辑环境配置模板
vi /root/setup_cdh_cluster/.env.template

# 修改以下配置项:
MYSQL_ROOT_PASSWORD=你的密码
DB_PASSWORD_SCM=你的密码
DB_PASSWORD_AMON=你的密码
# ... 其他密码 ...

# 2. 编辑 Ansible 配置
vi /root/setup_cdh_cluster/ansible/deploy_cdh.yml

# 在 password 部分修改:
password:
  mysql: 你的密码
  scm: 你的密码
  amon: 你的密码
  # ... 其他密码 ...
```

> ⚠️ **安全提示**：生产环境请使用复杂密码并妥善保管！

---

## 🔧 环境准备（手动配置）

> ⚠️ **注意**: 如果已经使用 `playground init`，**无需**再进行手动配置！以下内容仅供学习参考。

自动化部署前，如果不使用 playground，需要完成以下手动配置（仅需一次）

#### 配置 hostname
> 配置各个节点 IP 到 hostname 的映射
```bash
# 编辑 host 文件
vi /etc/hosts

# 添加下列 ip 和 hostname 映射
192.168.56.151  node01
192.168.56.152  node02
192.168.56.153  node03
```

#### 免密登录
> 配置 node01 免密登录到 node01~node03
``` bash
# node01 上安装
yum -y install openssh-clients
# node01 上生成密钥
ssh-keygen -t rsa

# node01 上复制 node01 的~/.ssh/id_rsa.pub 公钥到 node01~node03 的~/.ssh/authorized_keys 中
ssh-copy-id root@node01
ssh-copy-id root@node02
ssh-copy-id root@node03

# 在节点 node01 上测试
# 成功的话应该不用输入任何密码
ssh node02          

```

#### 安装 Ansible 2.8
``` bash
# node01 节点上安装 ansible 2.8
yum install -y centos-release-ansible-28.noarch

# 查看 ansible 版本
ansible --version
```

#### 上传组件安装包
百度云下载链接（总大小 4.49 GB）：[https://pan.baidu.com/s/1nbhiVhN0GWYUo9JmHgC4Pg](https://pan.baidu.com/s/1nbhiVhN0GWYUo9JmHgC4Pg)  密码：ax3w

压缩包内容:

**base_file/packages:**

1. cloudera-manager-agent-6.2.0-968826.el7.x86_64.rpm
2. cloudera-manager-daemons-6.2.0-968826.el7.x86_64.rpm
3. cloudera-manager-server-6.2.0-968826.el7.x86_64.rpm
4. cloudera-manager-server-db-2-6.2.0-968826.el7.x86_64.rpm
5. enterprise-debuginfo-6.3.1-1466458.el7.x86_64.rpm
6. get-pip.py
7. jdk-8u261-linux-x64.tar.gz
8. my.cnf
9. mysql-5.7.30-1.el7.x86_64.rpm-bundle.tar
10. mysql-community-client-5.7.30-1.el7.x86_64.rpm
11. mysql-community-common-5.7.30-1.el7.x86_64.rpm
12. mysql-community-devel-5.7.30-1.el7.x86_64.rpm
13. mysql-community-embedded-5.7.30-1.el7.x86_64.rpm
14. mysql-community-embedded-compat-5.7.30-1.el7.x86_64.rpm
15. mysql-community-embedded-devel-5.7.30-1.el7.x86_64.rpm
16. mysql-community-libs-5.7.30-1.el7.x86_64.rpm
17. mysql-community-libs-compat-5.7.30-1.el7.x86_64.rpm
18. mysql-community-server-5.7.30-1.el7.x86_64.rpm
19. mysql-community-test-5.7.30-1.el7.x86_64.rpm
20. mysql-connector-java-5.1.47.jar
21. mysql_init.sql
22. RPM-GPG-KEY-cloudera
23. scala-2.13.0-M4.tgz

**base_file/parcels:**

1. CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel
2. CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel.sha
3. CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel.sha256
4. KAFKA-4.1.0-1.4.1.0.p0.4-el7.parcel
5. KAFKA-4.1.0-1.4.1.0.p0.4-el7.parcel.sha1
6. manifest.json
7. SPARK2-2.4.0.cloudera1-1.cdh5.13.3.p0.1007356-el7.parcel
8. SPARK2-2.4.0.cloudera1-1.cdh5.13.3.p0.1007356-el7.parcel.sha

```bash
# 解压 zip 包上传组件安装包到 node01，得到两个目录
/opt/base_file/packages
/opt/base_file/parcels
```


#### 组件安装包下载出处
##### 1. JDK

| CDH 版本 | Oracle JDK 支持版本 | OpenJDK 支持版本 |
| --- | --- | --- |
| 5.3 -5.15 | 1.7, 1.8 | none |
| 5.16 and higher 5.x releases | 1.7, 1.8 | 1.8 |
| 6.0 | 1.8 | none |
| 6.1 | 1.8 | 1.8 |
| 6.2 | 1.8 | 1.8 |
| 6.3 | 1.8 | 1.8, 11.0.3 或更高版本 |



| Oracle JDK 版本 | 说明 |
| --- | --- |
| 1.8u181 或以上版本 | 推荐 |
| 1.8u162 | 推荐 |
| 1.8u141 | 推荐 |
| 1.8u131 | 推荐 |
| 1.8u121 | 推荐 |
| 1.8u111 | 推荐 |
| 1.8u102 | 推荐 |
| 1.8u91 | 推荐 |
| 1.8u74 | 推荐 |
| 1.8u31 | 不能低于该版本 |


| OpenJDK 版本  | 说明 |
| --- | --- |
| 1.8u212 或以上版本  | 推荐  |
| 1.8u181  | 不能低于该版本 |

官方对 JDK 要求说明：[传送门](https://docs.cloudera.com/documentation/enterprise/6/release-notes/topics/rg_java_requirements.html#java_requirements)

Oracle 1.8u261 下载: [传送门](https://download.oracle.com/otn/java/jdk/8u261-b12/a4634525489241b9a9e1aa73d9e118e6/jdk-8u261-linux-x64.tar.gz)

##### 2. Scala 2.13.0
[https://www.scala-lang.org/download/](https://www.scala-lang.org/download/)

##### 3. Mysql driver 5.1.47
[https://mvnrepository.com/artifact/mysql/mysql-connector-java/5.1.47](https://mvnrepository.com/artifact/mysql/mysql-connector-java/5.1.47)

##### 4. Mysql 5.7
[https://dev.mysql.com/downloads/mysql/5.7.html](https://dev.mysql.com/downloads/mysql/5.7.html)
[https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.30-1.el7.x86_64.rpm-bundle.tar](https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.30-1.el7.x86_64.rpm-bundle.tar)

##### 5. Cloudera Manger
[https://archive.cloudera.com/cm6/6.2.0/redhat7/yum/RPMS/x86_64/](https://archive.cloudera.com/cm6/6.2.0/redhat7/yum/RPMS/x86_64/)

##### 6. Parcels
[https://archive.cloudera.com/cdh6/6.3.2/parcels/](https://archive.cloudera.com/cdh6/6.3.2/parcels/)


#### 环境准备（v2.1 新增）

**方式 1：交互式初始化（推荐首次使用）**

```bash
cd /root/setup_cdh_cluster

# 一条命令完成所有环境准备
make init

# 特点：
# ✓ 交互式确认每个步骤
# ✓ 配置信息可视化显示
# ✓ 友好的错误提示
# ✓ 美观的进度显示
# ✓ 灵感来自 playground 项目
```

**方式 2：自动化准备（适合熟悉环境的用户）**

```bash
cd /root/setup_cdh_cluster

# 1. 创建配置文件
make env-file
vi .env  # 编辑配置

# 2. 一键准备环境
make prepare-env

# 3. 安装Python依赖
make install-deps

# 4. 运行环境测试
make test-env
```

#### 部署

**方法1：使用Makefile（推荐）**
```bash
cd /root/setup_cdh_cluster

# 查看可用命令
make help

# 完整部署流程
make full-deploy

# 或分步执行
make check          # 检查环境
make deploy         # 部署集群
make verify         # 验证部署
make test-full      # 测试部署
```

**方法2：使用管理脚本**
```bash
cd /root/setup_cdh_cluster
chmod +x scripts/manage_cluster.sh

# 一键部署
./scripts/manage_cluster.sh deploy

# 验证部署
./scripts/manage_cluster.sh verify
```

**方法3：使用ansible-playbook**
```bash
ansible-playbook -i /root/setup_cdh_cluster/ansible/node_group/hosts /root/setup_cdh_cluster/ansible/deploy_cdh.yml
```

#### 🌐 访问 Cloudera Manager Web 界面

部署完成后，等待 **3-5 分钟** 让 CM Server 完全启动，然后访问：

**主访问地址：**
```
http://node01:7180
```

**备用地址（使用 IP）：**
```
http://192.168.56.151:7180
```

**登录凭证：**
```
用户名: admin
密码:   admin
```

**启动确认：**
```bash
# 查看启动日志
tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log

# 等待看到 "Started Jetty server" 表示启动成功

# 检查端口
netstat -tlnp | grep 7180
```

📖 **详细访问指南**：[WEB_ACCESS_GUIDE.md](WEB_ACCESS_GUIDE.md)

## 运维和故障排查

### 健康检查
```bash
# 全面健康检查（推荐）
make health-check

# 深度诊断（依赖关系分析）
make diagnose

# 查看服务状态
make status
```

### 🛠️ 常见问题一键修复（v2.2 新增）

#### 1. 一键修复所有已知问题（推荐）⭐
```bash
make fix-all
```
**功能：**
- ✅ 修复 Agent 配置错误（server_host=localhost）
- ✅ 禁用 BitTorrent 分发（改用 HTTP）
- ✅ 配置 SSH 免警告
- ✅ 修复文件权限
- ✅ 准备 Parcel 分发

#### 2. Agent 配置错误
**问题：** CM 界面只显示 1 个节点，其他节点 Agent 无法连接

**修复：**
```bash
make fix-agent
```

#### 3. Parcel 分发失败
**错误：** `Failure due to stall on seeded torrent`

**修复：**
```bash
# 方式 1: 自动修复（推荐）
make fix-all

# 方式 2: 手动分发
make distribute-parcel
```

#### 4. MySQL 密码问题
```bash
make reset-mysql
```

#### 5. CM Server 连接错误
**错误信息：** `Communications link failure`

**原因：** CM Server 在 MySQL 之前启动

**修复：**
```bash
make fix-cm-mysql
```

#### 6. 服务启动顺序错误
```bash
make restart-services
```

#### 7. 完整诊断流程
```bash
# 1. 健康检查
make health-check

# 2. 发现问题后深度诊断
make diagnose

# 3. 一键修复（推荐）
make fix-all

# 4. 或根据诊断结果选择具体修复方案
make fix-agent           # Agent 配置问题
make distribute-parcel   # Parcel 分发问题
make fix-cm-mysql        # CM 连接问题
make reset-mysql         # MySQL 密码问题
make restart-services    # 服务顺序问题
```

### 🔧 修复工具汇总（v2.2）

| 工具 | 命令 | 说明 |
|-----|------|-----|
| ⭐ 一键修复 | `make fix-all` | 修复所有已知问题（推荐） |
| Agent 修复 | `make fix-agent` | 修复 Agent 配置错误 |
| Parcel 分发 | `make distribute-parcel` | 手动分发 CDH Parcel |
| 健康检查 | `make health-check` | 全面检查服务状态和依赖关系 |
| 深度诊断 | `make diagnose` | 分析启动顺序和错误日志 |
| CM MySQL 修复 | `make fix-cm-mysql` | 修复 CM Server MySQL 连接 |
| MySQL 重置 | `make reset-mysql` | 重置 MySQL 密码 |
| 服务重启 | `make restart-services` | 按正确顺序重启所有服务 |

📚 **详细文档：**
- [故障排查指南](doc/故障排查指南.md)
- [项目修复总结](doc/项目修复总结.md) - ⭐ v2.2 新增
- [集群启停指南](doc/集群启停指南.md) - ⭐ v2.2 新增
- [修复快速参考](FIXES_QUICK_REFERENCE.md) - ⭐ v2.2 新增

## 📚 文档中心

### 入门指南
- [快速开始指南](doc/快速开始指南.md) - 新手入门教程
- [交互式初始化指南](doc/交互式初始化指南.md) - ⭐ 优雅的环境初始化（灵感来自 playground）
- [base_file 目录准备](doc/base_file目录准备指南.md) - 安装包准备指南

### 部署相关
- [部署说明](doc/部署说明.md) - 详细部署步骤
- [Web 访问指南](WEB_ACCESS_GUIDE.md) - 🌐 Cloudera Manager Web 界面访问
- [部署警告说明](doc/部署警告说明.md) - 部署过程中警告的解释

### 运维管理（v2.2 更新）
- [集群启停指南](doc/集群启停指南.md) - ⭐ 启动、停止、重启操作
- [项目修复总结](doc/项目修复总结.md) - ⭐ 所有已修复问题汇总
- [修复快速参考](FIXES_QUICK_REFERENCE.md) - ⭐ 快速修复命令卡片
- [故障排查指南](doc/故障排查指南.md) - 问题诊断和修复

### 高级操作
- [删除集群指南](doc/删除集群指南.md) - ⚠️ 完全删除 CDH 集群（危险操作）
- [项目优化说明](doc/项目优化说明.md) - 优化记录
- [2025-11-12 全面优化](doc/2025-11-12-项目全面优化.md) - v2.1 工程化优化说明

## 更新日志

### v2.2 (2025-11-12) - 稳定性修复版
- 🔧 **新增** `make fix-all` - 一键修复所有已知问题（推荐）
- 🔧 **新增** `make fix-agent` - 修复 Agent 配置错误
- 🔧 **新增** `make distribute-parcel` - 手动分发 CDH Parcel
- 🐛 **修复** CM Agent 配置错误（server_host=localhost 问题）
- 🐛 **修复** Parcel BitTorrent 分发失败问题
- 🐛 **修复** SSH known_hosts 警告干扰问题
- ✨ **优化** 集群启停脚本（`cluster_control.sh`）
  - 自动验证和修复 Agent 配置
  - 智能等待 CM Server 启动
  - 详细的状态反馈和错误处理
- ✨ **更新** Ansible 部署 playbook，防止配置缺失
- 📝 **新增** 项目修复总结文档
- 📝 **新增** 集群启停指南
- 📝 **新增** 修复快速参考卡片

### v2.1 (2025-11-12) - 工程化优化版
- ✨ 新增 `make init` 交互式环境初始化（灵感来自 playground 项目）
- ✨ 新增 `make post-check` 部署后完整检查
- ✨ 新增 `make delall` 完全删除 CDH 集群（双重确认保护）
- ✨ 新增 `make health-check-v2` 优化版健康检查（美化输出）
- ✨ 新增 `make test-ssh` SSH 免密登录状态测试
- ✨ 新增 requirements.txt 依赖管理
- ✨ 新增 .env 环境配置系统
- ✨ 新增 Docker 完整支持
- ✨ 新增自动化测试框架
- ✨ 新增统一日志模块（`lib/output_formatter.sh`）
- ✨ 新增配置管理模块
- 🔧 优化 Makefile，增加测试和Docker命令
- 🔧 优化项目结构，提高模块化
- 🔧 优化部署完成提示，显示 Web 访问地址
- 🔧 优化所有脚本输出，统一美化风格
- 🐛 修复 Python 3.6 兼容性问题
- 📝 完善文档体系（新增交互式初始化、部署警告说明、删除集群指南等）

### v2.0 (2025-11-11)
- ✅ Python 3.8+ 支持
- ✅ 存储优化
- ✅ 服务依赖管理
- ✅ 健康检查功能

## ❓ FAQ

### Q: 下载虚拟机后如何使用？
**A:** 按照以下步骤：
1. 解压虚拟机文件
2. 使用 VirtualBox/VMware 导入虚拟机
3. 配置每个虚拟机为 4核CPU + 4GB内存
4. 启动所有3个节点
5. 准备安装包到 `/opt/base_file`
6. 在 node01 上运行 `make init` 初始化环境
7. 运行 `make deploy` 开始部署

### Q: CM 界面只显示 1 个节点？（v2.2 新增）
**A:** 这是 Agent 配置错误，使用一键修复：
```bash
make fix-all
```
或者只修复 Agent：
```bash
make fix-agent
```

### Q: Parcel 分发失败？（v2.2 新增）
**A:** 错误信息：`Failure due to stall on seeded torrent`

**解决方案：**
```bash
# 方式 1: 一键修复（推荐）
make fix-all

# 方式 2: 手动分发
make distribute-parcel
```

### Q: cloudera-scm-server 无法启动？
**A:** 常见原因和解决方案：

1. **MySQL 连接错误**
   ```bash
   # 查看日志确认错误
   tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log
   
   # 如果看到 "Communications link failure"
   make fix-cm-mysql
   ```

2. **MySQL 密码错误**
   ```bash
   make reset-mysql
   ```

3. **端口被占用**
   ```bash
   make force-stop
   make start
   ```

### Q: 遇到问题不知道如何修复？（v2.2 新增）
**A:** 使用一键修复命令：
```bash
make fix-all
```
这会自动修复所有已知问题，包括：
- Agent 配置错误
- BitTorrent 分发问题
- SSH 警告
- 文件权限问题

### Q: 如何查看详细日志？
```bash
# CM Server 日志
tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log

# MySQL 日志
tail -f /var/log/mysqld.log

# 部署日志
tail -f /var/log/cdh_deploy.log

# systemd 日志
journalctl -u cloudera-scm-server -n 100
```

### Q: 服务启动顺序是什么？
正确顺序：
1. MySQL (3306)
2. httpd (80)
3. cloudera-scm-server (7180)
4. cloudera-scm-agent (7182)

使用 `make diagnose` 可以检查实际启动顺序。

### Q: 与 playground 项目有什么关系？
**A:** 本项目深度参考了 [playground](https://gitee.com/several-boats/playground.git) 的设计理念：

**🔑 核心灵感 - SSH 免密登录（必看！）**
- ✅ **完全使用 playground 的方案**：`playground/systems/sshFreeLogin.sh`
- ✅ **expect 自动化**：自动处理 `yes/no` 和密码输入
- ✅ **批量配置**：自动配置所有节点的免密登录
- ✅ **验证机制**：自动检查免密登录是否成功

**其他参考之处：**
- 交互式初始化（`make init` vs `playground init`）
- YUM 源配置（`set_centos_repo_to_aliyun`）
- 系统依赖自动安装（`check_dependency`）
- 系统环境配置（防火墙、SELinux、时间同步）
- 集群节点同步（`update_all`）
- 成功提示框（ASCII 艺术）

**本项目的增强：**
- 专注于 CDH 集群部署
- 集成 Ansible 自动化
- 完善的诊断工具
- Makefile 统一管理
- 彩色日志输出
- 详细的错误处理
- `.env` 配置文件管理

**playground 使用示例：**
```bash
# playground 项目使用方式
cd /root
git clone https://gitee.com/several-boats/playground.git
cd playground
chmod +x playground.sh
./playground.sh install
playground init
# 是否安装 JDK? (yes/no): no
```

**本项目使用方式：**
```bash
# 本项目使用方式
cd /root
git clone <your-repo>/setup_cdh_cluster.git
cd setup_cdh_cluster
make init
# 按提示操作，无需安装 JDK（已包含在安装包中）
```

## Docker部署（v2.1 新增）

```bash
# 构建镜像
make docker-build

# 启动容器
make docker-up

# 进入容器
make docker-exec

# 在容器内部署
make deploy

# 查看日志
make docker-logs

# 停止容器
make docker-down
```

## 测试（v2.1 新增）

```bash
# 环境测试
make test-env

# 完整测试（需要先部署）
make test-full

# 查看测试报告
cat test_output/test_report_*.txt
```

## 项目结构（v2.1 更新）

```
setup_cdh_cluster/
├── ansible/              # Ansible脚本
├── scripts/              # Shell脚本
├── doc/                  # 文档目录
├── lib/                  # 公共库（新增）
│   ├── logger.py        # 日志模块
│   └── config.py        # 配置模块
├── tests/                # 测试目录（新增）
│   ├── test_environment.py
│   ├── test_deployment.py
│   └── run_tests.sh
├── requirements.txt      # Python依赖（新增）
├── .env.template         # 环境配置模板（新增）
├── Dockerfile            # Docker镜像（新增）
├── docker-compose.yml    # Docker编排（新增）
├── Makefile              # 构建脚本（增强）
└── README.md             # 项目说明
```

## TODO list
1. 集群进行水平扩展时，对新节点初始化配置
2. 添加自动化备份和恢复功能
3. 支持多版本 CDH 部署
4. Prometheus/Grafana 监控集成
5. Web 管理界面

## 参考
- 官方安装步骤: [https://docs.cloudera.com/documentation/enterprise/6/6.2/topics/installation.html](https://docs.cloudera.com/documentation/enterprise/6/6.2/topics/installation.html)
- MySQL 安装指南: [https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/cm_ig_mysql.html](https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/cm_ig_mysql.html)
