# CDH集群部署控制节点 Dockerfile
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# date: 2025-11-12
# 
# 功能说明：
# 此Dockerfile用于构建CDH集群部署的控制节点镜像
# 该镜像包含Ansible和所有必要的部署工具

# ==========================================
# 基础镜像
# ==========================================
FROM centos:7

# 维护者信息
LABEL maintainer="RaynLiu <liuyu1_j6go@stu.cqie.edu.cn>" \
      version="2.0" \
      description="CDH Cluster Deployment Control Node"

# ==========================================
# 环境变量
# ==========================================
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Shanghai \
    PYTHONUNBUFFERED=1 \
    PROJECT_DIR=/root/setup_cdh_cluster

# ==========================================
# 系统基础配置
# ==========================================
RUN set -ex && \
    # 配置YUM源为阿里云镜像（加速）
    sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-*.repo && \
    sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=https://mirrors.aliyun.com|g' /etc/yum.repos.d/CentOS-*.repo && \
    yum clean all && \
    yum makecache && \
    # 安装基础工具
    yum install -y \
        epel-release \
        wget \
        curl \
        vim \
        git \
        openssh-clients \
        openssh-server \
        net-tools \
        which \
        sudo && \
    yum clean all && \
    rm -rf /var/cache/yum

# ==========================================
# Python环境配置
# ==========================================
RUN set -ex && \
    # 安装Python 3
    yum install -y \
        python3 \
        python3-pip \
        python3-devel \
        gcc \
        make && \
    # 配置pip镜像源
    mkdir -p /root/.pip && \
    echo "[global]" > /root/.pip/pip.conf && \
    echo "index-url = https://mirrors.aliyun.com/pypi/simple/" >> /root/.pip/pip.conf && \
    echo "trusted-host = mirrors.aliyun.com" >> /root/.pip/pip.conf && \
    # 升级pip
    python3 -m pip install --upgrade pip && \
    yum clean all && \
    rm -rf /var/cache/yum

# ==========================================
# 工作目录配置
# ==========================================
WORKDIR ${PROJECT_DIR}

# 复制依赖文件
COPY requirements.txt ${PROJECT_DIR}/

# ==========================================
# 安装Python依赖
# ==========================================
RUN set -ex && \
    pip3 install --no-cache-dir -r requirements.txt && \
    # 创建Ansible软链接
    ln -sf /usr/local/bin/ansible /usr/bin/ansible 2>/dev/null || true && \
    ln -sf /usr/local/bin/ansible-playbook /usr/bin/ansible-playbook 2>/dev/null || true && \
    # 验证安装
    ansible --version && \
    python3 --version

# ==========================================
# 复制项目文件
# ==========================================
COPY . ${PROJECT_DIR}/

# ==========================================
# 配置SSH
# ==========================================
RUN set -ex && \
    # 配置SSH服务
    ssh-keygen -A && \
    # 设置权限
    chmod +x ${PROJECT_DIR}/scripts/*.sh && \
    chmod +x ${PROJECT_DIR}/Makefile

# ==========================================
# 创建日志目录
# ==========================================
RUN mkdir -p /var/log && \
    touch /var/log/cdh_deploy.log && \
    chmod 644 /var/log/cdh_deploy.log

# ==========================================
# 健康检查
# ==========================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD [ "ansible", "--version" ] || exit 1

# ==========================================
# 暴露端口（SSH）
# ==========================================
EXPOSE 22

# ==========================================
# 启动命令
# ==========================================
# 默认启动bash，也可以通过docker-compose启动sshd
CMD ["/bin/bash"]

# ==========================================
# 使用说明
# ==========================================
# 构建镜像：
#   docker build -t cdh-deploy:latest .
#
# 运行容器：
#   docker run -it --name cdh-control cdh-deploy:latest
#
# 或使用docker-compose：
#   docker-compose up -d
# ==========================================
