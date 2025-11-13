#!/bin/bash
# CDH 集群完全删除脚本
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# date: 2025-11-12
# 警告: 此脚本会删除所有 CDH 集群相关内容，不可恢复！

# 加载输出格式化库
PROJECT_DIR=/root/setup_cdh_cluster
source "$PROJECT_DIR/lib/output_formatter.sh" 2>/dev/null || {
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
    log_error() { echo -e "${RED}[✗]${NC} $1"; }
    log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
    log_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
    log_step() { echo -e "[→] $1"; }
    print_header() { echo ""; echo "=========================================="; echo "  $1"; echo "=========================================="; echo ""; }
}

INVENTORY="$PROJECT_DIR/ansible/node_group/hosts"

# ==========================================
# 删除前安全检查
# ==========================================
pre_delete_check() {
    print_header "删除前安全检查"
    
    # 检查 base_file 目录
    log_step "验证 /opt/base_file 目录..."
    if [ -d "/opt/base_file" ]; then
        local file_count=$(ls -1 /opt/base_file 2>/dev/null | wc -l)
        log_success "/opt/base_file 存在，包含 $file_count 个文件/目录"
        log_warning "删除脚本会保留此目录"
    else
        log_warning "/opt/base_file 不存在"
    fi
    
    # 检查要删除的目录
    echo ""
    log_step "扫描将要删除的目录..."
    
    local targets=(
        "/opt/cloudera"
        "/var/lib/cloudera-scm-server"
        "/var/lib/cloudera-scm-agent"
        "/usr/java"
        "/usr/local/scala"
        "/var/log/cloudera-scm-server"
        "/dfs"
        "/yarn"
    )
    
    local total_size=0
    for target in "${targets[@]}"; do
        if [ -e "$target" ]; then
            local size=$(du -sh "$target" 2>/dev/null | cut -f1)
            echo "  [找到] $target ($size)"
        fi
    done
    
    # 检查运行的服务
    echo ""
    log_step "检查运行中的 CDH 服务..."
    
    local services_running=false
    if systemctl is-active cloudera-scm-server >/dev/null 2>&1; then
        echo "  [运行中] cloudera-scm-server"
        services_running=true
    fi
    
    if systemctl is-active mysqld >/dev/null 2>&1; then
        echo "  [运行中] mysqld"
        services_running=true
    fi
    
    if [ "$services_running" = true ]; then
        log_warning "检测到 CDH 服务正在运行，删除时会先停止"
    else
        log_success "没有检测到运行中的 CDH 服务"
    fi
    
    echo ""
}

# ==========================================
# 确认函数
# ==========================================
confirm_delete() {
    print_header "⚠️  危险操作警告"
    
    echo -e "${RED}此操作将删除以下内容：${NC}"
    echo "  • 停止所有 CDH 服务（CM Server、CM Agent）"
    echo "  • 卸载 Cloudera Manager"
    echo "  • 卸载 MySQL 数据库"
    echo "  • 删除所有 CDH 数据目录"
    echo "  • 删除 Java 和 Scala"
    echo "  • 删除所有配置文件"
    echo "  • 清理环境变量"
    echo ""
    echo -e "${GREEN}✓ 以下内容会保留：${NC}"
    echo "  • /opt/base_file 目录（安装包，可重新部署）"
    echo "  • 系统关键服务和进程"
    echo "  • 非 CDH 相关的配置"
    echo ""
    echo -e "${RED}⚠️  CDH 数据将无法恢复！${NC}"
    echo ""
    
    read -p "$(echo -e ${YELLOW}确认删除 CDH 集群？输入 'DELETE' 继续: ${NC})" confirm
    
    if [ "$confirm" != "DELETE" ]; then
        log_warning "用户取消操作"
        exit 0
    fi
    
    echo ""
    read -p "$(echo -e ${RED}最后确认：真的要删除吗？[yes/no]: ${NC})" final_confirm
    
    if [ "$final_confirm" != "yes" ]; then
        log_warning "用户取消操作"
        exit 0
    fi
}

# ==========================================
# 停止所有服务
# ==========================================
stop_all_services() {
    print_header "步骤 1/10: 停止 CDH 相关服务"
    
    log_step "停止 Cloudera Manager Server..."
    systemctl stop cloudera-scm-server 2>/dev/null || true
    systemctl disable cloudera-scm-server 2>/dev/null || true
    
    log_step "停止所有节点的 Cloudera Manager Agent..."
    for node in node01 node02 node03; do
        ssh $node "systemctl stop cloudera-scm-agent 2>/dev/null || true" || true
        ssh $node "systemctl disable cloudera-scm-agent 2>/dev/null || true" || true
        echo "  停止 $node 的 Agent"
    done
    
    log_step "停止 MySQL（CDH 专用）..."
    # 只停止 MySQL，不删除系统级别的 MySQL
    systemctl stop mysqld 2>/dev/null || true
    
    log_step "停止 httpd（本地仓库）..."
    # 只停止 httpd，不影响系统其他 web 服务
    systemctl stop httpd 2>/dev/null || true
    
    log_warning "⚠️ 只停止 CDH 相关服务，不影响系统服务"
    log_success "CDH 服务已停止"
}

# ==========================================
# 卸载 Cloudera Manager
# ==========================================
uninstall_cloudera_manager() {
    print_header "步骤 2/10: 卸载 Cloudera Manager"
    
    log_step "卸载 CM Server..."
    yum remove -y cloudera-manager-server 2>/dev/null || true
    
    log_step "卸载所有节点的 CM Agent 和 Daemons..."
    for node in node01 node02 node03; do
        ssh $node "yum remove -y cloudera-manager-agent cloudera-manager-daemons" 2>/dev/null || true
        echo "  卸载 $node 的组件"
    done
    
    log_success "Cloudera Manager 已卸载"
}

# ==========================================
# 卸载 MySQL
# ==========================================
uninstall_mysql() {
    print_header "步骤 3/10: 卸载 MySQL"
    
    log_step "卸载 MySQL..."
    yum remove -y mysql-community-* 2>/dev/null || true
    
    log_step "删除 MySQL 数据目录..."
    rm -rf /var/lib/mysql
    
    log_step "删除 MySQL 配置..."
    rm -f /etc/my.cnf*
    
    log_success "MySQL 已卸载"
}

# ==========================================
# 删除数据目录
# ==========================================
remove_data_directories() {
    print_header "步骤 4/10: 删除数据目录"
    
    # ⚠️ 重要：只删除 CDH 相关目录，保留 /opt/base_file
    local dirs=(
        "/opt/cloudera"
        "/var/lib/cloudera-scm-server"
        "/var/lib/cloudera-scm-agent"
        "/var/log/cloudera-scm-server"
        "/var/log/cloudera-scm-agent"
        "/var/run/cloudera-scm-server"
        "/var/run/cloudera-scm-agent"
        "/dfs"
        "/yarn"
    )
    
    for node in node01 node02 node03; do
        log_step "清理 $node 数据目录..."
        for dir in "${dirs[@]}"; do
            # 确保不删除 /opt/base_file
            if [[ "$dir" != *"base_file"* ]]; then
                ssh $node "rm -rf $dir" 2>/dev/null || true
            fi
        done
        
        # 单独处理 /opt/cm-* 目录，避免通配符误删
        ssh $node "find /opt -maxdepth 1 -name 'cm-*' -type d -exec rm -rf {} +" 2>/dev/null || true
    done
    
    log_warning "⚠️ 已保留 /opt/base_file 目录（安装包）"
    log_success "数据目录已删除"
}

# ==========================================
# 删除 Parcels
# ==========================================
remove_parcels() {
    print_header "步骤 5/10: 删除 Parcels"
    
    log_step "删除 Parcel 目录..."
    for node in node01 node02 node03; do
        ssh $node "rm -rf /opt/cloudera/parcels" 2>/dev/null || true
        ssh $node "rm -rf /opt/cloudera/parcel-cache" 2>/dev/null || true
        ssh $node "rm -rf /opt/cloudera/parcel-repo" 2>/dev/null || true
        echo "  清理 $node 的 Parcels"
    done
    
    log_success "Parcels 已删除"
}

# ==========================================
# 删除 Java 和 Scala
# ==========================================
remove_java_scala() {
    print_header "步骤 6/10: 删除 Java 和 Scala"
    
    log_step "删除所有节点的 Java 和 Scala..."
    for node in node01 node02 node03; do
        ssh $node "rm -rf /usr/java" 2>/dev/null || true
        ssh $node "rm -rf /usr/local/scala*" 2>/dev/null || true
        ssh $node "rm -f /usr/local/scala" 2>/dev/null || true
        echo "  清理 $node 的 Java/Scala"
    done
    
    log_success "Java 和 Scala 已删除"
}

# ==========================================
# 清理环境变量
# ==========================================
clean_environment_variables() {
    print_header "步骤 7/10: 清理环境变量"
    
    log_step "清理所有节点的环境变量..."
    for node in node01 node02 node03; do
        ssh $node "sed -i '/JAVA_HOME/d' /etc/profile" 2>/dev/null || true
        ssh $node "sed -i '/JRE_HOME/d' /etc/profile" 2>/dev/null || true
        ssh $node "sed -i '/SCALA_HOME/d' /etc/profile" 2>/dev/null || true
        ssh $node "sed -i '/CDH/d' /etc/profile" 2>/dev/null || true
        echo "  清理 $node 的环境变量"
    done
    
    log_success "环境变量已清理"
}

# ==========================================
# 删除 YUM 仓库配置
# ==========================================
remove_yum_repos() {
    print_header "步骤 8/10: 删除 YUM 仓库配置"
    
    log_step "删除 YUM 仓库配置..."
    for node in node01 node02 node03; do
        ssh $node "rm -f /etc/yum.repos.d/cloudera*.repo" 2>/dev/null || true
        ssh $node "yum clean all" 2>/dev/null || true
        echo "  清理 $node 的 YUM 配置"
    done
    
    log_success "YUM 仓库配置已删除"
}

# ==========================================
# 删除 httpd 本地仓库
# ==========================================
remove_local_repo() {
    print_header "步骤 9/10: 删除本地 YUM 仓库"
    
    log_step "停止并卸载 httpd..."
    systemctl stop httpd 2>/dev/null || true
    yum remove -y httpd 2>/dev/null || true
    
    log_step "删除仓库文件..."
    rm -rf /var/www/html/cloudera-repos
    
    log_success "本地仓库已删除"
}

# ==========================================
# 清理日志和临时文件
# ==========================================
clean_logs_and_temp() {
    print_header "步骤 10/10: 清理日志和临时文件"
    
    log_step "清理所有节点的日志..."
    for node in node01 node02 node03; do
        ssh $node "rm -rf /var/log/cloudera-*" 2>/dev/null || true
        ssh $node "rm -rf /tmp/scm_*" 2>/dev/null || true
        ssh $node "rm -rf /tmp/cloudera-*" 2>/dev/null || true
        echo "  清理 $node 的日志"
    done
    
    # 清理部署日志
    log_step "清理部署日志..."
    rm -f /var/log/cdh_deploy.log 2>/dev/null || true
    
    log_success "日志和临时文件已清理"
}

# ==========================================
# 显示汇总
# ==========================================
show_summary() {
    print_header "删除完成"
    
    echo ""
    echo "✅ 已删除的内容："
    echo "  ✓ Cloudera Manager Server & Agent"
    echo "  ✓ MySQL 数据库"
    echo "  ✓ Java & Scala 环境"
    echo "  ✓ CDH 数据目录"
    echo "  ✓ CDH 配置文件"
    echo "  ✓ 环境变量"
    echo "  ✓ YUM 仓库配置"
    echo "  ✓ 本地 YUM 仓库"
    echo "  ✓ 日志和临时文件"
    echo ""
    echo "🛡️  已保留的内容："
    echo "  ✓ /opt/base_file 目录（安装包）"
    echo "  ✓ 系统关键服务"
    echo "  ✓ 系统配置文件"
    echo ""
    echo "集群已完全删除！"
    echo ""
    echo "如需重新部署："
    echo "  cd /root/setup_cdh_cluster"
    echo "  make init      # 初始化环境"
    echo "  make deploy    # 部署集群"
    echo ""
}

# ==========================================
# 主函数
# ==========================================
main() {
    print_header "CDH 集群完全删除"
    
    echo "作者: RaynLiu"
    echo "日期: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # 删除前安全检查
    pre_delete_check
    
    # 确认删除
    confirm_delete
    
    echo ""
    log_warning "开始删除 CDH 集群..."
    echo ""
    
    # 执行删除步骤
    stop_all_services
    uninstall_cloudera_manager
    uninstall_mysql
    remove_data_directories
    remove_parcels
    remove_java_scala
    clean_environment_variables
    remove_yum_repos
    remove_local_repo
    clean_logs_and_temp
    
    # 显示汇总
    show_summary
}

# 运行主函数
main
