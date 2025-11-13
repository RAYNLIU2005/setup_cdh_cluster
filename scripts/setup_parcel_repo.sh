#!/bin/bash
# 配置 CDH Parcel HTTP 仓库
# 自动配置 httpd 服务器，提供 Parcel 文件的 HTTP 访问
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_header() {
    echo ""
    echo "=========================================="
    echo "  配置 CDH Parcel HTTP 仓库"
    echo "=========================================="
    echo ""
}

# 配置变量
PARCEL_SOURCE_DIR="/opt/base_file/parcels"
PARCEL_REPO_DIR="/opt/cloudera/parcel-repo"
HTTP_ROOT="/var/www/html"

# 检查 Parcel 源文件
check_parcel_files() {
    log_info "检查 Parcel 源文件..."
    
    if [ ! -d "$PARCEL_SOURCE_DIR" ]; then
        log_error "Parcel 源目录不存在: $PARCEL_SOURCE_DIR"
        log_error "请先上传并解压 parcels.tar.gz 到 /opt/base_file/"
        return 1
    fi
    
    # 检查 CDH Parcel 文件
    local cdh_parcel=$(ls -1 $PARCEL_SOURCE_DIR/CDH-*.parcel 2>/dev/null | head -1)
    if [ -z "$cdh_parcel" ]; then
        log_error "未找到 CDH Parcel 文件"
        log_error "请确保 $PARCEL_SOURCE_DIR 目录下有 CDH-*.parcel 文件"
        return 1
    fi
    
    log_success "找到 CDH Parcel: $(basename $cdh_parcel)"
    
    # 检查 SHA 文件
    local sha_file=$(ls -1 $PARCEL_SOURCE_DIR/CDH-*.parcel.sha* 2>/dev/null | head -1)
    if [ -z "$sha_file" ]; then
        log_warning "未找到 SHA 文件，可能影响 Parcel 验证"
    else
        log_success "找到 SHA 文件: $(basename $sha_file)"
    fi
    
    # 检查 manifest.json
    if [ -f "$PARCEL_SOURCE_DIR/manifest.json" ]; then
        log_success "找到 manifest.json"
    else
        log_warning "未找到 manifest.json，可能影响 Parcel 列表"
    fi
    
    return 0
}

# 安装并配置 httpd
setup_httpd() {
    log_info "配置 HTTP 服务器..."
    
    # 检查 httpd 是否已安装
    if ! rpm -q httpd &>/dev/null; then
        log_info "安装 httpd..."
        yum install -y httpd &>/dev/null
        if [ $? -ne 0 ]; then
            log_error "httpd 安装失败"
            return 1
        fi
        log_success "httpd 安装完成"
    else
        log_success "httpd 已安装"
    fi
    
    # 启动并设置开机自启
    log_info "启动 httpd 服务..."
    systemctl start httpd
    systemctl enable httpd &>/dev/null
    
    if systemctl is-active --quiet httpd; then
        log_success "httpd 服务已启动"
    else
        log_error "httpd 服务启动失败"
        return 1
    fi
    
    # 配置防火墙（如果启用）
    if systemctl is-active --quiet firewalld; then
        log_info "配置防火墙..."
        firewall-cmd --permanent --add-service=http &>/dev/null
        firewall-cmd --reload &>/dev/null
        log_success "防火墙已配置"
    fi
    
    return 0
}

# 复制 Parcel 文件到仓库
setup_parcel_repository() {
    log_info "设置 Parcel 仓库..."
    
    # 创建 parcel-repo 目录
    mkdir -p "$PARCEL_REPO_DIR"
    
    # 复制 CDH Parcel 文件
    log_info "复制 CDH Parcel 文件..."
    cp -f $PARCEL_SOURCE_DIR/CDH-*.parcel "$PARCEL_REPO_DIR/" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_success "CDH Parcel 文件已复制"
    else
        log_error "CDH Parcel 文件复制失败"
        return 1
    fi
    
    # 处理 SHA 文件（确保扩展名为 .sha）
    log_info "处理 SHA 文件..."
    local sha_files=$(ls -1 $PARCEL_SOURCE_DIR/CDH-*.parcel.sha* 2>/dev/null)
    for sha_file in $sha_files; do
        local base_name=$(basename "$sha_file" | sed 's/\.sha.*//')
        cp -f "$sha_file" "$PARCEL_REPO_DIR/${base_name}.sha"
    done
    
    if ls $PARCEL_REPO_DIR/CDH-*.parcel.sha &>/dev/null; then
        log_success "SHA 文件已处理"
    else
        log_warning "SHA 文件处理可能失败"
    fi
    
    # 复制 manifest.json
    if [ -f "$PARCEL_SOURCE_DIR/manifest.json" ]; then
        log_info "复制 manifest.json..."
        cp -f "$PARCEL_SOURCE_DIR/manifest.json" "$PARCEL_REPO_DIR/"
        log_success "manifest.json 已复制"
    fi
    
    # 设置权限
    log_info "设置文件权限..."
    chown -R cloudera-scm:cloudera-scm "$PARCEL_REPO_DIR" 2>/dev/null || chown -R root:root "$PARCEL_REPO_DIR"
    chmod 755 "$PARCEL_REPO_DIR"
    chmod 644 "$PARCEL_REPO_DIR"/*
    log_success "权限已设置"
    
    return 0
}

# 创建 HTTP 软链接
create_http_link() {
    log_info "创建 HTTP 访问链接..."
    
    # 删除旧链接
    rm -f "$HTTP_ROOT/parcel-repo" 2>/dev/null
    
    # 创建软链接
    ln -s "$PARCEL_REPO_DIR" "$HTTP_ROOT/parcel-repo"
    
    if [ -L "$HTTP_ROOT/parcel-repo" ]; then
        log_success "HTTP 链接已创建: $HTTP_ROOT/parcel-repo -> $PARCEL_REPO_DIR"
    else
        log_error "HTTP 链接创建失败"
        return 1
    fi
    
    # 设置 SELinux 上下文（如果启用）
    if command -v getenforce &>/dev/null && [ "$(getenforce)" != "Disabled" ]; then
        log_info "配置 SELinux 上下文..."
        chcon -R -t httpd_sys_content_t "$PARCEL_REPO_DIR" 2>/dev/null
        log_success "SELinux 上下文已配置"
    fi
    
    return 0
}

# 验证 HTTP 访问
verify_http_access() {
    log_info "验证 HTTP 访问..."
    echo ""
    
    local hostname=$(hostname)
    local test_url="http://$hostname/parcel-repo/manifest.json"
    
    # 测试 HTTP 访问
    if curl -s -f "$test_url" >/dev/null 2>&1; then
        log_success "HTTP 访问测试成功"
        echo "  访问地址: http://$hostname/parcel-repo/"
    else
        log_warning "HTTP 访问测试失败"
        echo "  请手动验证: curl http://$hostname/parcel-repo/manifest.json"
    fi
    
    echo ""
    echo "  Parcel 仓库内容:"
    ls -lh "$PARCEL_REPO_DIR" | grep -E "\.parcel$|\.sha$|manifest.json" | awk '{printf "    %s %s\n", $9, $5}'
    
    return 0
}

# 主函数
main() {
    print_header
    
    log_info "开始配置 Parcel HTTP 仓库..."
    echo ""
    
    # 执行配置步骤
    local failed=0
    
    if ! check_parcel_files; then
        ((failed++))
        exit 1
    fi
    
    echo ""
    
    if ! setup_httpd; then
        ((failed++))
        exit 1
    fi
    
    echo ""
    
    if ! setup_parcel_repository; then
        ((failed++))
        exit 1
    fi
    
    echo ""
    
    if ! create_http_link; then
        ((failed++))
        exit 1
    fi
    
    echo ""
    
    verify_http_access
    
    # 总结
    echo "=========================================="
    if [ $failed -eq 0 ]; then
        log_success "Parcel HTTP 仓库配置完成！"
        echo ""
        log_info "配置信息："
        echo "  ✓ HTTP 服务: httpd (已启动)"
        echo "  ✓ Parcel 仓库: $PARCEL_REPO_DIR"
        echo "  ✓ HTTP 访问: http://$(hostname)/parcel-repo/"
        echo ""
        log_info "在 Cloudera Manager 中使用以下 URL："
        echo "  http://node01/parcel-repo/"
    else
        log_error "Parcel HTTP 仓库配置失败！"
        exit 1
    fi
    echo "=========================================="
    echo ""
}

# 执行主函数
main
