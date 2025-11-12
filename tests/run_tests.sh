#!/bin/bash
# CDH集群测试执行脚本
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn
# date: 2025-11-12
#
# 功能说明：
# 执行所有测试用例并生成测试报告

set -e

# ==========================================
# 配置变量
# ==========================================
PROJECT_DIR="/root/setup_cdh_cluster"
TEST_DIR="${PROJECT_DIR}/tests"
TEST_OUTPUT_DIR="${PROJECT_DIR}/test_output"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${TEST_OUTPUT_DIR}/test_report_${TIMESTAMP}.txt"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==========================================
# 日志函数
# ==========================================
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# ==========================================
# 初始化
# ==========================================
init_test_env() {
    log_section "初始化测试环境"
    
    # 创建输出目录
    mkdir -p "${TEST_OUTPUT_DIR}"
    
    # 初始化报告文件
    cat > "${REPORT_FILE}" << EOF
========================================
CDH集群部署测试报告
========================================
测试时间: $(date '+%Y-%m-%d %H:%M:%S')
作者: RaynLiu
邮箱: liuyu1_j6go@stu.cqie.edu.cn
========================================

EOF
    
    log_info "测试输出目录: ${TEST_OUTPUT_DIR}"
    log_info "测试报告文件: ${REPORT_FILE}"
}

# ==========================================
# 运行环境测试
# ==========================================
run_environment_tests() {
    log_section "运行环境测试"
    
    echo "环境测试结果:" >> "${REPORT_FILE}"
    echo "----------------------------------------" >> "${REPORT_FILE}"
    
    if python3 "${TEST_DIR}/test_environment.py" 2>&1 | tee -a "${REPORT_FILE}"; then
        log_info "✓ 环境测试通过"
        echo "✓ 环境测试: 通过" >> "${REPORT_FILE}"
        return 0
    else
        log_error "✗ 环境测试失败"
        echo "✗ 环境测试: 失败" >> "${REPORT_FILE}"
        return 1
    fi
}

# ==========================================
# 运行部署测试
# ==========================================
run_deployment_tests() {
    log_section "运行部署测试"
    
    echo "" >> "${REPORT_FILE}"
    echo "部署测试结果:" >> "${REPORT_FILE}"
    echo "----------------------------------------" >> "${REPORT_FILE}"
    
    if python3 "${TEST_DIR}/test_deployment.py" 2>&1 | tee -a "${REPORT_FILE}"; then
        log_info "✓ 部署测试通过"
        echo "✓ 部署测试: 通过" >> "${REPORT_FILE}"
        return 0
    else
        log_error "✗ 部署测试失败"
        echo "✗ 部署测试: 失败" >> "${REPORT_FILE}"
        return 1
    fi
}

# ==========================================
# 生成测试摘要
# ==========================================
generate_summary() {
    log_section "生成测试摘要"
    
    cat >> "${REPORT_FILE}" << EOF

========================================
测试摘要
========================================
总测试数: $1
通过: $2
失败: $3
成功率: $(awk "BEGIN {printf \"%.2f\", ($2/$1)*100}")%
========================================

EOF
    
    log_info "测试摘要已生成"
}

# ==========================================
# 显示测试报告
# ==========================================
show_report() {
    log_section "测试报告"
    
    cat "${REPORT_FILE}"
    
    echo ""
    log_info "完整报告已保存至: ${REPORT_FILE}"
}

# ==========================================
# 主函数
# ==========================================
main() {
    log_section "CDH集群测试套件"
    log_info "作者: RaynLiu"
    log_info "邮箱: liuyu1_j6go@stu.cqie.edu.cn"
    echo ""
    
    # 初始化
    init_test_env
    
    # 测试计数器
    total_tests=0
    passed_tests=0
    failed_tests=0
    
    # 运行环境测试
    if run_environment_tests; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    ((total_tests++))
    
    # 运行部署测试（可选，需要部署后才能运行）
    if [ "$1" == "--full" ]; then
        if run_deployment_tests; then
            ((passed_tests++))
        else
            ((failed_tests++))
        fi
        ((total_tests++))
    else
        log_warn "跳过部署测试（使用 --full 参数运行完整测试）"
    fi
    
    # 生成摘要
    generate_summary ${total_tests} ${passed_tests} ${failed_tests}
    
    # 显示报告
    show_report
    
    # 退出状态
    if [ ${failed_tests} -eq 0 ]; then
        log_section "✓ 所有测试通过"
        exit 0
    else
        log_section "✗ 部分测试失败"
        exit 1
    fi
}

# ==========================================
# 执行主函数
# ==========================================
main "$@"
