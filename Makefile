# CDH集群部署 Makefile
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# date: 2025-11-12

.PHONY: help check clean deploy verify status start stop restart force-stop nodes check-nodes add-nodes fix-agent fix-all distribute-parcel start-all stop-all health ps ports logs install-ansible prepare-env fix-yum diagnose-yum setup-python setup-ssh fix-permissions reset-mysql cleanup-copies quick-deploy full-deploy check-env health-check health-check-v2 diagnose fix-cm-mysql restart-services install-deps test test-env test-env-v2 test-full docker-build docker-up docker-down docker-logs docker-exec docker-clean env-file post-check init test-ssh check-disk show-format check-delete delall sync-nodes optimize-performance optimize-all-nodes setup-parcel-repo

PROJECT_DIR := /root/setup_cdh_cluster
INVENTORY := $(PROJECT_DIR)/ansible/node_group/hosts
PLAYBOOK := $(PROJECT_DIR)/ansible/deploy_cdh.yml

help:
	@echo "╔══════════════════════════════════════════════════════════════════╗"
	@echo "║                   CDH 集群部署管理系统 v2.2                      ║"
	@echo "║                    Copyright © 2025 RaynLiu                      ║"
	@echo "║                  Email: liuyu1_j6go@stu.cqie.edu.cn             ║"
	@echo "╚══════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "🔑 默认密码: 123456 (SSH/MySQL/所有组件数据库)"
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════════════╗"
	@echo "║ 🚀 快速开始 (推荐新手使用)                                       ║"
	@echo "╚══════════════════════════════════════════════════════════════════╝"
	@echo "  make init            ⭐ 交互式环境初始化 (使用 playground)"
	@echo "  make full-deploy     🚀 一键完整部署 (环境准备+部署+验证)"
	@echo "  make quick-deploy    ⚡ 快速重新部署 (清理+部署+验证)"
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════════════╗"
	@echo "║ ⚙️  环境准备命令                                                 ║"
	@echo "╚══════════════════════════════════════════════════════════════════╝"
	@echo "  make prepare-env           🔧 一键准备所有环境 (自动化)"
	@echo "  make optimize-all-nodes    ⚡ 优化所有节点性能 (禁用THP/调整swap)"
	@echo "  make setup-parcel-repo     📦 配置 Parcel HTTP 仓库"
	@echo "  make setup-ssh             🔑 配置 SSH 免密登录"
	@echo "  make test-ssh              🔍 测试 SSH 连接状态"
	@echo "  make check-disk            💾 检查磁盘空间"
	@echo "  make fix-yum               🔧 修复 YUM 源问题"
	@echo "  make check-env             ✅ 检查环境是否就绪"
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════════════╗"
	@echo "║ 📦 部署管理命令                                                   ║"
	@echo "╚══════════════════════════════════════════════════════════════════╝"
	@echo "  make check                 🔍 检查磁盘空间和系统状态"
	@echo "  make deploy                🚀 部署 CDH 集群"
	@echo "  make verify                ✅ 验证部署状态"
	@echo "  make cleanup-copies        🧹 清理复制文件，释放空间"
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════════════╗"
	@echo "║ 🎛️  集群管理命令                                                 ║"
	@echo "╚══════════════════════════════════════════════════════════════════╝"
	@echo "  make status                📊 查看集群服务状态"
	@echo "  make start                 ▶️  启动集群所有服务"
	@echo "  make stop                  ⏹️  停止集群所有服务"
	@echo "  make restart               🔄 重启集群所有服务"
	@echo "  make nodes                 🖥️  查看所有节点状态"
	@echo "  make check-nodes           🔍 检查节点健康状况"
	@echo "  make add-nodes             ➕ 添加节点到集群"
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════════════╗"
	@echo "║ 🔧 故障修复命令                                                   ║"
	@echo "╚══════════════════════════════════════════════════════════════════╝"
	@echo "  make fix-all               🛠️  修复所有已知问题 (推荐)"
	@echo "  make fix-agent             🔧 修复 Agent 配置错误"
	@echo "  make reset-mysql           🔑 重置 MySQL 密码为 123456"
	@echo "  make fix-cm-mysql          🔧 修复 CM Server MySQL 连接"
	@echo "  make fix-permissions       🔓 修复脚本执行权限"
	@echo "  make restart-services      🔄 按正确顺序重启服务"
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════════════╗"
	@echo "║ 📊 监控诊断命令                                                   ║"
	@echo "╚══════════════════════════════════════════════════════════════════╝"
	@echo "  make post-check            ✅ 部署后完整检查 (推荐)"
	@echo "  make health-check-v2       💚 优化版健康检查"
	@echo "  make diagnose              🔬 深度诊断 (依赖分析)"
	@echo "  make ps                    👁️  查看 Cloudera 进程"
	@echo "  make ports                 🔌 查看服务端口占用"
	@echo "  make logs                  📝 查看部署日志"
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════════════╗"
	@echo "║ ⚠️  危险操作命令 (谨慎使用)                                      ║"
	@echo "╚══════════════════════════════════════════════════════════════════╝"
	@echo "  make check-delete          🔍 删除前安全检查"
	@echo "  make delall                💣 完全删除 CDH 集群 (不可恢复)"
	@echo ""
	@echo "💡 提示: 使用 'make <command>' 执行命令"
	@echo "📖 文档: https://github.com/RaynLiu/setup_cdh_cluster"
	@echo ""

# ==========================================
# 环境准备命令
# ==========================================

# 交互式环境初始化（推荐首次使用）
init:
	@echo "=========================================="
	@echo "  交互式环境初始化"
	@echo "  灵感来自 playground 项目"
	@echo "  Copyright © 2025 RaynLiu"
	@echo "=========================================="
	@echo ""
	@chmod +x $(PROJECT_DIR)/scripts/init_environment.sh
	@$(PROJECT_DIR)/scripts/init_environment.sh

# 一键准备所有环境（自动化版本）
prepare-env:
	@echo "=========================================="
	@echo "  准备 CDH 部署环境"
	@echo "  Copyright © 2025 RaynLiu"
	@echo "=========================================="
	@echo ""
	@echo "[1/7] 修复 YUM 源..."
	@$(MAKE) fix-yum
	@echo ""
	@echo "[2/7] 安装 Python 3..."
	@$(MAKE) setup-python
	@echo ""
	@echo "[3/7] 安装 Ansible..."
	@$(MAKE) install-ansible
	@echo ""
	@echo "[4/7] 修复所有节点 YUM 源..."
	@for node in node01 node02 node03; do \
		echo "  修复 $$node..."; \
		ssh $$node "rm -f /etc/yum.repos.d/*ansible*.repo && yum clean all" 2>/dev/null || true; \
	done
	@echo ""
	@echo "[5/7] 优化所有节点性能（禁用透明大页、调整swappiness）..."
	@$(MAKE) optimize-all-nodes
	@echo ""
	@echo "[6/7] 配置 Parcel HTTP 仓库..."
	@$(MAKE) setup-parcel-repo
	@echo ""
	@echo "[7/7] 检查环境..."
	@$(MAKE) check-env
	@echo ""
	@echo "=========================================="
	@echo "  ✓ 环境准备完成！"
	@echo "=========================================="
	@echo ""
	@echo "💡 提示："
	@echo "  推荐首次使用: make init  （交互式，更友好）"
	@echo ""
	@echo "下一步："
	@echo "  make deploy    # 开始部署 CDH 集群"
	@echo ""

# 配置 SSH 免密登录
setup-ssh:
	@echo "==> 配置 SSH 免密登录..."
	@chmod +x $(PROJECT_DIR)/scripts/setup_ssh_keys.sh
	@$(PROJECT_DIR)/scripts/setup_ssh_keys.sh

# 测试 SSH 免密登录状态
test-ssh:
	@chmod +x $(PROJECT_DIR)/scripts/test_ssh.sh
	@$(PROJECT_DIR)/scripts/test_ssh.sh

# 同步项目到其他节点（参考 playground 的 update_all）
sync-nodes:
	@echo "==> 同步项目到集群节点..."
	@chmod +x $(PROJECT_DIR)/scripts/sync_to_nodes.sh
	@$(PROJECT_DIR)/scripts/sync_to_nodes.sh

# 检查磁盘空间
check-disk:
	@chmod +x $(PROJECT_DIR)/scripts/check_disk_space.sh
	@$(PROJECT_DIR)/scripts/check_disk_space.sh

# 修复 YUM 源（参考 playground 优化）
fix-yum:
	@echo "==> 修复 YUM 源..."
	@chmod +x $(PROJECT_DIR)/scripts/fix_yum_repos.sh
	@$(PROJECT_DIR)/scripts/fix_yum_repos.sh
	@echo ""
	@echo "==> 清理和重建 YUM 缓存..."
	@yum clean all >/dev/null 2>&1 || true
	@yum makecache fast 2>&1 || echo "⚠ YUM 缓存重建失败（可能是网络问题）"
	@echo ""
	@echo "✓ YUM 源修复完成"
	@echo ""
	@echo "💡 提示："
	@echo "  如果仍有问题，运行: make diagnose-yum"
	@echo ""

# YUM 源诊断（网络、配置、缓存全面检查）
diagnose-yum:
	@echo "==> YUM 源诊断..."
	@chmod +x $(PROJECT_DIR)/scripts/diagnose_yum.sh
	@$(PROJECT_DIR)/scripts/diagnose_yum.sh

# 优化当前节点性能
optimize-performance:
	@echo "==> 优化当前节点性能..."
	@chmod +x $(PROJECT_DIR)/scripts/optimize_system_performance.sh
	@$(PROJECT_DIR)/scripts/optimize_system_performance.sh

# 优化所有集群节点性能
optimize-all-nodes:
	@echo "==> 优化所有集群节点性能..."
	@chmod +x $(PROJECT_DIR)/scripts/optimize_all_nodes.sh
	@$(PROJECT_DIR)/scripts/optimize_all_nodes.sh

# 配置 Parcel HTTP 仓库
setup-parcel-repo:
	@echo "==> 配置 Parcel HTTP 仓库..."
	@chmod +x $(PROJECT_DIR)/scripts/setup_parcel_repo.sh
	@$(PROJECT_DIR)/scripts/setup_parcel_repo.sh

# 安装配置 Python 3
setup-python:
	@echo "==> 安装 Python 3..."
	@if ! command -v python3 >/dev/null 2>&1; then \
		yum install -y python3 python3-pip python3-devel; \
	else \
		echo "✓ Python 3 已安装: $$(python3 --version)"; \
	fi
	@echo "==> 配置 pip 镜像..."
	@mkdir -p ~/.pip
	@echo "[global]" > ~/.pip/pip.conf
	@echo "index-url = https://mirrors.aliyun.com/pypi/simple/" >> ~/.pip/pip.conf
	@echo "trusted-host = mirrors.aliyun.com" >> ~/.pip/pip.conf
	@echo "==> 升级 pip..."
	@python3 -m pip install --upgrade pip -q
	@echo "==> 安装 Python 依赖..."
	@pip3 install pymysql -q
	@echo "✓ Python 环境配置完成"
	@python3 --version
	@pip3 --version

# 安装 Ansible
install-ansible:
	@echo "==> 安装 Ansible..."
	@if ! command -v ansible >/dev/null 2>&1; then \
		pip3 install ansible==2.9.27 -q; \
		ln -sf /usr/local/bin/ansible /usr/bin/ansible 2>/dev/null || true; \
		ln -sf /usr/local/bin/ansible-playbook /usr/bin/ansible-playbook 2>/dev/null || true; \
	else \
		echo "✓ Ansible 已安装"; \
	fi
	@echo "✓ Ansible 安装完成"
	@ansible --version | head -1

# 检查环境
check-env:
	@echo "==> 检查环境..."
	@chmod +x $(PROJECT_DIR)/scripts/check_python_env.sh
	@$(PROJECT_DIR)/scripts/check_python_env.sh || true
	@echo ""
	@echo "测试 Ansible 连接..."
	@ansible all_node -i $(INVENTORY) -m ping 2>/dev/null || echo "⚠ 部分节点连接失败（部署时会自动处理）"

check:
	@echo "=========================================="
	@echo "  CDH集群部署管理系统"
	@echo "  Copyright © 2025 RaynLiu"
	@echo "  保留所有权利 All Rights Reserved"
	@echo "=========================================="
	@echo ""
	@echo "==> 检查环境..."
	@chmod +x $(PROJECT_DIR)/scripts/check_disk_space.sh
	@$(PROJECT_DIR)/scripts/check_disk_space.sh
	@echo "==> 检查节点连通性..."
	@ansible all -i $(INVENTORY) -m ping

clean:
	@echo "==> 清理系统..."
	@echo "清理临时文件..."
	@rm -f /tmp/cdh_*.log 2>/dev/null || true
	@rm -f /tmp/mysql_password_* 2>/dev/null || true
	@echo "✓ 清理完成"

deploy:
	@echo "=========================================="
	@echo "  CDH集群部署管理系统"
	@echo "  Copyright © 2025 RaynLiu"
	@echo "  保留所有权利 All Rights Reserved"
	@echo "=========================================="
	@echo ""
	@echo "==> 开始部署CDH集群..."
	@ansible-playbook -i $(INVENTORY) $(PLAYBOOK) || (echo "[ERROR] 部署失败" && exit 1)
	@echo "[SUCCESS] 部署完成"

verify:
	@echo "==> 验证部署..."
	@chmod +x $(PROJECT_DIR)/scripts/post_deploy_check.sh
	@$(PROJECT_DIR)/scripts/post_deploy_check.sh

start:
	@echo "==> 启动集群..."
	@chmod +x $(PROJECT_DIR)/scripts/cluster_control.sh
	@$(PROJECT_DIR)/scripts/cluster_control.sh start

stop:
	@echo "==> 停止集群..."
	@chmod +x $(PROJECT_DIR)/scripts/cluster_control.sh
	@$(PROJECT_DIR)/scripts/cluster_control.sh stop

restart:
	@echo "==> 重启集群..."
	@chmod +x $(PROJECT_DIR)/scripts/cluster_control.sh
	@$(PROJECT_DIR)/scripts/cluster_control.sh restart

status:
	@chmod +x $(PROJECT_DIR)/scripts/cluster_control.sh
	@$(PROJECT_DIR)/scripts/cluster_control.sh status

force-stop:
	@echo "==> 强制停止所有服务..."
	@echo "停止 Cloudera Manager..."
	@systemctl stop cloudera-scm-server 2>/dev/null || true
	@for node in node01 node02 node03; do ssh $$node "systemctl stop cloudera-scm-agent" 2>/dev/null || true; done
	@echo "清理残留进程..."
	@pkill -9 -f cloudera 2>/dev/null || true
	@echo "✓ 强制停止完成"

nodes:
	@echo "==> 检查所有节点连通性..."
	@ansible all -i $(INVENTORY) -m ping

# 检查集群节点状态
check-nodes:
	@chmod +x $(PROJECT_DIR)/scripts/check_cluster_nodes.sh
	@$(PROJECT_DIR)/scripts/check_cluster_nodes.sh

# 添加节点到集群
add-nodes:
	@chmod +x $(PROJECT_DIR)/scripts/add_cluster_nodes.sh
	@$(PROJECT_DIR)/scripts/add_cluster_nodes.sh

# 修复 Agent 配置
fix-agent:
	@chmod +x $(PROJECT_DIR)/scripts/fix_agent_config.sh
	@$(PROJECT_DIR)/scripts/fix_agent_config.sh

# 修复所有已知问题
fix-all:
	@chmod +x $(PROJECT_DIR)/scripts/fix_all_issues.sh
	@$(PROJECT_DIR)/scripts/fix_all_issues.sh

# 手动分发 Parcel
distribute-parcel:
	@chmod +x $(PROJECT_DIR)/scripts/manual_distribute_parcel.sh
	@$(PROJECT_DIR)/scripts/manual_distribute_parcel.sh

start-all:
	@echo "==> 启动所有节点..."
	@chmod +x $(PROJECT_DIR)/scripts/cluster_control.sh
	@$(PROJECT_DIR)/scripts/cluster_control.sh start

stop-all:
	@echo "==> 停止所有节点..."
	@chmod +x $(PROJECT_DIR)/scripts/cluster_control.sh
	@$(PROJECT_DIR)/scripts/cluster_control.sh stop

health:
	@echo "==> 执行健康检查..."
	@chmod +x $(PROJECT_DIR)/scripts/health_check_v2.sh
	@$(PROJECT_DIR)/scripts/health_check_v2.sh

ps:
	@echo "==> 查看进程..."
	@echo "Cloudera 相关进程:"
	@ps aux | grep -E '(cloudera|mysql|httpd)' | grep -v grep || echo "无相关进程运行"

ports:
	@echo "==> 查看端口占用..."
	@echo "CDH 相关端口:"
	@netstat -tuln | grep -E '(3306|7180|7182|50070|8088|10000)' || echo "无相关端口监听"

logs:
	@echo "==> 查看日志..."
	@echo "最近的部署日志:"
	@tail -50 /var/log/cdh_deploy.log 2>/dev/null || echo "日志文件不存在"
	@echo ""
	@echo "CM Server 日志:"
	@tail -20 /var/log/cloudera-scm-server/cloudera-scm-server.log 2>/dev/null || echo "日志文件不存在"

# 快速部署（清理+部署+验证）
quick-deploy: clean deploy verify
	@echo ""
	@echo "=========================================="
	@echo "  🎉 快速部署完成！"
	@echo "=========================================="
	@echo ""
	@echo "🌐 访问 Cloudera Manager："
	@echo "  http://node01:7180 (admin/admin)"
	@echo ""
	@echo "📋 后续操作："
	@echo "  make status        - 查看服务状态"
	@echo "  make health-check  - 健康检查"
	@echo "=========================================="
	@echo ""

# 完整部署流程（包含环境准备）
full-deploy: prepare-env check clean deploy verify
	@echo ""
	@echo "=========================================="
	@echo "  🎉 完整部署流程完成！"
	@echo "=========================================="
	@echo ""
	@echo "⏱  CM Server 启动：预计需要 3-5 分钟"
	@echo ""
	@echo "🌐 访问 Cloudera Manager Web 界面："
	@echo "  URL:  http://node01:7180"
	@echo "  或:   http://192.168.56.151:7180"
	@echo ""
	@echo "  默认账号: admin"
	@echo "  默认密码: admin"
	@echo ""
	@echo "📋 后续操作："
	@echo "  make status        - 查看服务状态"
	@echo "  make health-check  - 健康检查"
	@echo "  make test-full     - 完整测试"
	@echo "  make logs          - 查看日志"
	@echo ""
	@echo "📝 提示：等待 CM Server 启动后再访问 Web 界面"
	@echo "=========================================="
	@echo ""

# 清理复制文件，使用软链接替代
cleanup-copies:
	@echo "==> 清理复制文件，释放磁盘空间..."
	@echo "清理 Parcel 缓存..."
	@for node in node01 node02 node03; do \
		ssh $$node "rm -rf /opt/cloudera/parcel-cache/*.parcel 2>/dev/null || true"; \
	done
	@echo "✓ 清理完成"

# ==========================================
# 故障修复命令
# ==========================================

# 修复所有脚本执行权限
fix-permissions:
	@echo "==> 修复所有脚本执行权限..."
	@chmod +x $(PROJECT_DIR)/scripts/*.sh
	@echo "✓ 所有脚本权限已修复"

# 重置 MySQL Root 密码
reset-mysql:
	@echo "==> 重置 MySQL Root 密码..."
	@chmod +x $(PROJECT_DIR)/scripts/reset_mysql_password.sh
	@$(PROJECT_DIR)/scripts/reset_mysql_password.sh

# 健康检查（使用优化版）
health-check:
	@echo "==> 执行健康检查..."
	@chmod +x $(PROJECT_DIR)/scripts/health_check_v2.sh
	@$(PROJECT_DIR)/scripts/health_check_v2.sh

# 优化版健康检查（美化输出） - 别名
health-check-v2:
	@chmod +x $(PROJECT_DIR)/scripts/health_check_v2.sh
	@$(PROJECT_DIR)/scripts/health_check_v2.sh

# 深度诊断
diagnose:
	@echo "==> 执行深度诊断..."
	@chmod +x $(PROJECT_DIR)/scripts/diagnose_dependencies.sh
	@$(PROJECT_DIR)/scripts/diagnose_dependencies.sh

# 修复 CM Server MySQL 连接
fix-cm-mysql:
	@echo "==> 修复 CM Server MySQL 连接..."
	@chmod +x $(PROJECT_DIR)/scripts/fix_cm_mysql_connection.sh
	@$(PROJECT_DIR)/scripts/fix_cm_mysql_connection.sh

# 按正确顺序重启服务
restart-services:
	@echo "==> 按正确顺序重启所有服务..."
	@chmod +x $(PROJECT_DIR)/scripts/restart_services.sh
	@$(PROJECT_DIR)/scripts/restart_services.sh

# ==========================================
# 依赖管理命令
# ==========================================

# 安装Python依赖
install-deps:
	@echo "==> 安装Python依赖..."
	@if [ -f $(PROJECT_DIR)/requirements.txt ]; then \
		pip3 install -r $(PROJECT_DIR)/requirements.txt; \
		echo "✓ 依赖安装完成"; \
	else \
		echo "⚠ requirements.txt 不存在"; \
	fi

# ==========================================
# 测试命令
# ==========================================

# 运行环境测试
test-env:
	@echo "==> 运行环境测试..."
	@chmod +x $(PROJECT_DIR)/tests/run_tests.sh
	@python3 $(PROJECT_DIR)/tests/test_environment.py

# 运行环境测试（优化版）
test-env-v2:
	@chmod +x $(PROJECT_DIR)/tests/run_tests_v2.sh
	@$(PROJECT_DIR)/tests/run_tests_v2.sh

# 运行完整测试
test-full:
	@echo "==> 运行完整测试..."
	@chmod +x $(PROJECT_DIR)/tests/run_tests.sh
	@$(PROJECT_DIR)/tests/run_tests.sh --full

# 别名
test: test-env

# ==========================================
# Docker命令
# ==========================================

# 构建Docker镜像
docker-build:
	@echo "==> 构建Docker镜像..."
	@docker build -t cdh-deploy:latest $(PROJECT_DIR)
	@echo "✓ 镜像构建完成"

# 启动Docker容器
docker-up:
	@echo "==> 启动Docker容器..."
	@cd $(PROJECT_DIR) && docker-compose up -d
	@echo "✓ 容器已启动"
	@echo "使用 'make docker-exec' 进入容器"

# 停止Docker容器
docker-down:
	@echo "==> 停止Docker容器..."
	@cd $(PROJECT_DIR) && docker-compose down
	@echo "✓ 容器已停止"

# 查看Docker日志
docker-logs:
	@echo "==> 查看Docker日志..."
	@cd $(PROJECT_DIR) && docker-compose logs -f

# 进入Docker容器
docker-exec:
	@echo "==> 进入Docker容器..."
	@cd $(PROJECT_DIR) && docker-compose exec cdh-control bash

# 清理Docker环境
docker-clean:
	@echo "==> 清理Docker环境..."
	@cd $(PROJECT_DIR) && docker-compose down -v
	@docker rmi cdh-deploy:latest 2>/dev/null || true
	@echo "✓ Docker环境已清理"

# ==========================================
# 配置管理命令
# ==========================================

# 创建.env文件
env-file:
	@echo "==> 创建.env配置文件..."
	@if [ ! -f $(PROJECT_DIR)/.env ]; then \
		cp $(PROJECT_DIR)/.env.template $(PROJECT_DIR)/.env; \
		echo "✓ .env文件已创建，请编辑配置"; \
		echo "  vi $(PROJECT_DIR)/.env"; \
	else \
		echo "⚠ .env文件已存在"; \
	fi

# ==========================================
# 部署后检查命令
# ==========================================

# 部署后完整检查
post-check:
	@echo "==> 运行部署后完整检查..."
	@chmod +x $(PROJECT_DIR)/scripts/post_deploy_check.sh
	@$(PROJECT_DIR)/scripts/post_deploy_check.sh

# ==========================================
# 输出格式命令
# ==========================================

# 显示输出格式样例
show-format:
	@chmod +x $(PROJECT_DIR)/lib/output_formatter.sh
	@bash $(PROJECT_DIR)/lib/output_formatter.sh

# ==========================================
# 危险操作命令
# ==========================================

# 删除前安全检查（已集成到 delete_cluster.sh 中）
check-delete:
	@echo "==> 删除前安全检查..."
	@echo ""
	@echo "💡 提示：安全检查已集成到删除脚本中"
	@echo "直接运行 'make delall' 即可，会自动进行安全检查"
	@echo ""
	@echo "或者查看将要删除的内容："
	@echo "  • /opt/cloudera"
	@echo "  • /var/lib/cloudera-scm-*"
	@echo "  • /usr/java"
	@echo "  • /usr/local/scala"
	@echo ""
	@echo "✓ 会保留: /opt/base_file（安装包）"
	@echo ""

# 完全删除 CDH 集群
delall:
	@echo ""
	@echo "=========================================="
	@echo "  ⚠️  危险操作：完全删除 CDH 集群"
	@echo "=========================================="
	@echo ""
	@echo "🛡️  安全保护："
	@echo "  ✓ 保留 /opt/base_file（安装包）"
	@echo "  ✓ 保护系统关键服务"
	@echo ""
	@echo "❌ 将要删除："
	@echo "  • Cloudera Manager"
	@echo "  • MySQL 数据库"
	@echo "  • Java 和 Scala"
	@echo "  • CDH 数据目录"
	@echo "  • CDH 配置文件"
	@echo ""
	@echo "⚠️  数据将无法恢复！"
	@echo ""
	@echo "💡 建议先运行: make check-delete"
	@echo ""
	@chmod +x $(PROJECT_DIR)/scripts/delete_cluster.sh
	@$(PROJECT_DIR)/scripts/delete_cluster.sh
