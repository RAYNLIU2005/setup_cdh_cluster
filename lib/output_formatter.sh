#!/bin/bash
# 统一的输出格式化库
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# date: 2025-11-12

# ==========================================
# 颜色定义
# ==========================================
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export WHITE='\033[1;37m'
export GRAY='\033[0;90m'
export NC='\033[0m'

# 背景色
export BG_RED='\033[41m'
export BG_GREEN='\033[42m'
export BG_YELLOW='\033[43m'
export BG_BLUE='\033[44m'

# ==========================================
# 符号定义
# ==========================================
export SYMBOL_SUCCESS="✓"
export SYMBOL_ERROR="✗"
export SYMBOL_WARNING="⚠"
export SYMBOL_INFO="ℹ"
export SYMBOL_ARROW="→"
export SYMBOL_STAR="★"
export SYMBOL_CLOCK="⏱"
export SYMBOL_ROCKET="🚀"
export SYMBOL_TOOLS="🔧"
export SYMBOL_CHECK="🔍"

# ==========================================
# 日志函数
# ==========================================

# 成功信息
log_success() {
    echo -e "${GREEN}[${SYMBOL_SUCCESS}]${NC} $1"
}

# 错误信息
log_error() {
    echo -e "${RED}[${SYMBOL_ERROR}]${NC} $1"
}

# 警告信息
log_warning() {
    echo -e "${YELLOW}[${SYMBOL_WARNING}]${NC} $1"
}

# 普通信息
log_info() {
    echo -e "${CYAN}[${SYMBOL_INFO}]${NC} $1"
}

# 步骤信息
log_step() {
    echo -e "${BLUE}[${SYMBOL_ARROW}]${NC} $1"
}

# 调试信息
log_debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        echo -e "${GRAY}[DEBUG]${NC} $1"
    fi
}

# ==========================================
# 分隔线函数
# ==========================================

# 双线分隔
print_double_line() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 单线分隔
print_single_line() {
    echo "────────────────────────────────────────────────────────────────────"
}

# 等号分隔
print_equal_line() {
    echo "===================================================================="
}

# 虚线分隔
print_dash_line() {
    echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
}

# ==========================================
# 标题函数
# ==========================================

# 主标题
print_header() {
    local title="$1"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}  $title${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# 子标题
print_subheader() {
    local title="$1"
    echo ""
    echo -e "${CYAN}── $title ──${NC}"
    echo ""
}

# 章节标题（用于步骤标题）
print_section() {
    local title="$1"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $title${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# 成功标题
print_success_header() {
    local title="$1"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ${SYMBOL_SUCCESS} $title${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# 错误标题
print_error_header() {
    local title="$1"
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  ${SYMBOL_ERROR} $title${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# 警告标题
print_warning_header() {
    local title="$1"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  ${SYMBOL_WARNING} $title${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ==========================================
# 状态显示函数
# ==========================================

# 显示状态行
print_status() {
    local item="$1"
    local status="$2"
    local detail="${3:-}"
    
    case "$status" in
        ok|success|pass)
            echo -e "  ${GREEN}${SYMBOL_SUCCESS}${NC} ${item}${detail:+ - }${GRAY}${detail}${NC}"
            ;;
        fail|error)
            echo -e "  ${RED}${SYMBOL_ERROR}${NC} ${item}${detail:+ - }${GRAY}${detail}${NC}"
            ;;
        warn|warning)
            echo -e "  ${YELLOW}${SYMBOL_WARNING}${NC} ${item}${detail:+ - }${GRAY}${detail}${NC}"
            ;;
        skip)
            echo -e "  ${GRAY}○${NC} ${item}${detail:+ - }${GRAY}${detail}${NC}"
            ;;
        *)
            echo -e "  ${CYAN}•${NC} ${item}${detail:+ - }${GRAY}${detail}${NC}"
            ;;
    esac
}

# ==========================================
# 进度显示函数
# ==========================================

# 显示进度
print_progress() {
    local current=$1
    local total=$2
    local title="${3:-进度}"
    
    local percentage=$((current * 100 / total))
    local filled=$((percentage / 2))
    local empty=$((50 - filled))
    
    printf "\r${CYAN}[${NC}"
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "${CYAN}]${NC} ${percentage}%% ${title} (${current}/${total})"
}

# 完成进度显示
print_progress_done() {
    echo ""
}

# ==========================================
# 表格显示函数
# ==========================================

# 表格行
print_table_row() {
    local col1="$1"
    local col2="$2"
    local col3="${3:-}"
    
    if [ -n "$col3" ]; then
        printf "  %-30s %-30s %-20s\n" "$col1" "$col2" "$col3"
    else
        printf "  %-40s %-30s\n" "$col1" "$col2"
    fi
}

# 表格头
print_table_header() {
    print_single_line
}

# ==========================================
# 提示函数
# ==========================================

# 提示框
print_tip() {
    local message="$1"
    echo ""
    echo -e "${CYAN}┌─────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} 💡 ${YELLOW}提示${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}   $message"
    echo -e "${CYAN}└─────────────────────────────────────────────┘${NC}"
    echo ""
}

# 警告框
print_alert() {
    local message="$1"
    echo ""
    echo -e "${YELLOW}┌─────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${NC} ${SYMBOL_WARNING} ${YELLOW}警告${NC}"
    echo -e "${YELLOW}├─────────────────────────────────────────────┤${NC}"
    echo -e "${YELLOW}│${NC}   $message"
    echo -e "${YELLOW}└─────────────────────────────────────────────┘${NC}"
    echo ""
}

# 错误框
print_error_box() {
    local message="$1"
    echo ""
    echo -e "${RED}┌─────────────────────────────────────────────┐${NC}"
    echo -e "${RED}│${NC} ${SYMBOL_ERROR} ${RED}错误${NC}"
    echo -e "${RED}├─────────────────────────────────────────────┤${NC}"
    echo -e "${RED}│${NC}   $message"
    echo -e "${RED}└─────────────────────────────────────────────┘${NC}"
    echo ""
}

# ==========================================
# 加载动画
# ==========================================

# 旋转加载动画
show_spinner() {
    local pid=$1
    local message="${2:-处理中}"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r${CYAN}${spin:$i:1}${NC} $message..."
        sleep 0.1
    done
    printf "\r"
}

# ==========================================
# 汇总函数
# ==========================================

# 显示汇总
print_summary() {
    local title="$1"
    shift
    
    print_header "$title"
    
    while [ $# -gt 0 ]; do
        echo -e "  ${CYAN}•${NC} $1"
        shift
    done
    
    echo ""
}

# ==========================================
# 横幅
# ==========================================

# 显示欢迎横幅
print_banner() {
    local title="$1"
    local subtitle="${2:-}"
    local author="${3:-RaynLiu}"
    
    echo ""
    print_double_line
    echo -e "${WHITE}  $title${NC}"
    if [ -n "$subtitle" ]; then
        echo -e "${GRAY}  $subtitle${NC}"
    fi
    echo -e "${GRAY}  Copyright © 2025 $author${NC}"
    print_double_line
    echo ""
}

# ==========================================
# 确认函数
# ==========================================

# 确认提示
confirm() {
    local message="$1"
    local default="${2:-n}"
    local response
    
    if [ "$default" = "y" ]; then
        read -p "$(echo -e ${YELLOW}${message} [Y/n]: ${NC})" response
        response=${response:-y}
    else
        read -p "$(echo -e ${YELLOW}${message} [y/N]: ${NC})" response
        response=${response:-n}
    fi
    
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ==========================================
# 错误处理和容错函数
# ==========================================

# 捕获错误并退出
die() {
    local message="$1"
    local exit_code="${2:-1}"
    
    print_error_box "$message"
    exit "$exit_code"
}

# 检查命令是否成功
check_command() {
    local command="$1"
    local error_message="${2:-命令执行失败: $command}"
    
    if ! $command; then
        die "$error_message" 1
    fi
}

# 安全执行命令（带重试）
safe_exec() {
    local command="$1"
    local max_retries="${2:-3}"
    local retry_delay="${3:-2}"
    local attempt=1
    
    while [ $attempt -le $max_retries ]; do
        if eval "$command"; then
            return 0
        fi
        
        if [ $attempt -lt $max_retries ]; then
            log_warning "命令失败，${retry_delay}秒后重试... (尝试 $attempt/$max_retries)"
            sleep "$retry_delay"
        fi
        
        attempt=$((attempt + 1))
    done
    
    log_error "命令执行失败（已重试 $max_retries 次）: $command"
    return 1
}

# 检查文件是否存在
check_file_exists() {
    local file="$1"
    local error_message="${2:-文件不存在: $file}"
    
    if [ ! -f "$file" ]; then
        die "$error_message" 2
    fi
}

# 检查目录是否存在
check_dir_exists() {
    local dir="$1"
    local error_message="${2:-目录不存在: $dir}"
    
    if [ ! -d "$dir" ]; then
        die "$error_message" 2
    fi
}

# 检查服务是否运行
check_service_running() {
    local service="$1"
    
    if systemctl is-active "$service" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 等待服务启动
wait_for_service() {
    local service="$1"
    local timeout="${2:-60}"
    local interval="${3:-2}"
    local elapsed=0
    
    log_step "等待服务 $service 启动..."
    
    while [ $elapsed -lt $timeout ]; do
        if check_service_running "$service"; then
            log_success "服务 $service 已启动"
            return 0
        fi
        
        sleep "$interval"
        elapsed=$((elapsed + interval))
        printf "."
    done
    
    echo ""
    log_error "服务 $service 启动超时（${timeout}秒）"
    return 1
}

# 检查端口是否监听
check_port_listening() {
    local port="$1"
    local host="${2:-localhost}"
    
    if command -v nc >/dev/null 2>&1; then
        nc -z "$host" "$port" >/dev/null 2>&1
    elif command -v telnet >/dev/null 2>&1; then
        timeout 1 telnet "$host" "$port" >/dev/null 2>&1
    else
        netstat -tuln | grep -q ":${port} "
    fi
}

# 等待端口监听
wait_for_port() {
    local port="$1"
    local host="${2:-localhost}"
    local timeout="${3:-60}"
    local interval="${4:-2}"
    local elapsed=0
    
    log_step "等待端口 $port 监听..."
    
    while [ $elapsed -lt $timeout ]; do
        if check_port_listening "$port" "$host"; then
            log_success "端口 $port 已监听"
            return 0
        fi
        
        sleep "$interval"
        elapsed=$((elapsed + interval))
        printf "."
    done
    
    echo ""
    log_error "端口 $port 监听超时（${timeout}秒）"
    return 1
}

# 检查磁盘空间
check_disk_space() {
    local path="$1"
    local required_gb="${2:-10}"
    
    local available_kb=$(df -k "$path" | tail -1 | awk '{print $4}')
    local available_gb=$((available_kb / 1024 / 1024))
    
    if [ $available_gb -lt $required_gb ]; then
        log_error "磁盘空间不足: $path (可用: ${available_gb}GB, 需要: ${required_gb}GB)"
        return 1
    else
        log_success "磁盘空间充足: $path (可用: ${available_gb}GB)"
        return 0
    fi
}

# 创建备份
create_backup() {
    local file="$1"
    local backup_dir="${2:-/tmp/backups}"
    
    if [ -f "$file" ]; then
        mkdir -p "$backup_dir"
        local backup_file="$backup_dir/$(basename "$file").bak.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup_file"
        log_success "已备份: $file -> $backup_file"
        return 0
    else
        log_warning "文件不存在，无需备份: $file"
        return 1
    fi
}

# 安全删除（带确认）
safe_remove() {
    local target="$1"
    local force="${2:-false}"
    
    if [ ! -e "$target" ]; then
        log_warning "目标不存在: $target"
        return 0
    fi
    
    if [ "$force" = "false" ]; then
        if ! confirm "确认删除 $target？"; then
            log_info "用户取消删除"
            return 1
        fi
    fi
    
    rm -rf "$target"
    log_success "已删除: $target"
}

# ==========================================
# 使用示例
# ==========================================

# 如果直接运行此脚本，显示示例
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    print_banner "输出格式化库" "统一的输出风格" "RaynLiu"
    
    print_header "日志函数示例"
    log_success "这是成功信息"
    log_error "这是错误信息"
    log_warning "这是警告信息"
    log_info "这是普通信息"
    log_step "这是步骤信息"
    
    print_header "状态显示示例"
    print_status "MySQL 服务" "ok" "运行正常"
    print_status "httpd 服务" "fail" "未启动"
    print_status "防火墙" "warn" "未关闭"
    print_status "测试服务" "skip" "已跳过"
    
    print_header "表格显示示例"
    print_table_header
    print_table_row "服务" "状态" "端口"
    print_single_line
    print_table_row "MySQL" "运行中" "3306"
    print_table_row "CM Server" "运行中" "7180"
    print_table_row "httpd" "已停止" "80"
    print_single_line
    
    print_tip "这是一个提示信息"
    print_alert "这是一个警告信息"
    print_error_box "这是一个错误信息"
    
    print_success_header "操作成功完成"
    
    echo "所有样式演示完成！"
    echo ""
fi
