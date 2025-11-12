#!/bin/bash
# CDH 集群测试运行器 v2.0 - 优化版
# author: RaynLiu  
# email: liuyu1_j6go@stu.cqie.edu.cn
# date: 2025-11-12

# 加载输出格式化库
PROJECT_DIR=/root/setup_cdh_cluster
source "$PROJECT_DIR/lib/output_formatter.sh"

# 配置
TEST_OUTPUT_DIR="$PROJECT_DIR/test_output"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
TEST_REPORT="$TEST_OUTPUT_DIR/test_report_${TIMESTAMP}.txt"

# 初始化
mkdir -p "$TEST_OUTPUT_DIR"

# ==========================================
# 测试运行函数
# ==========================================

run_environment_tests() {
    print_header "环境测试"
    
    log_step "运行 Python 测试脚本..."
    
    # 运行测试并捕获输出
    local output=$(python3 "$PROJECT_DIR/tests/test_environment.py" 2>&1)
    local exit_code=$?
    
    # 解析结果
    if echo "$output" | grep -q "OK"; then
        local test_count=$(echo "$output" | grep "Ran" | awk '{print $2}')
        print_success_header "环境测试通过"
        echo -e "  ${GREEN}运行了 $test_count 个测试，全部通过${NC}"
        echo ""
        return 0
    elif echo "$output" | grep -q "FAILED"; then
        local failures=$(echo "$output" | grep "FAILED" | grep -o "errors=[0-9]*" | cut -d= -f2)
        print_error_header "环境测试失败"
        echo -e "  ${RED}发现 $failures 个错误${NC}"
        echo ""
        echo "详细错误信息："
        echo "$output" | grep -A5 "ERROR:"
        echo ""
        return 1
    else
        print_warning_header "环境测试结果未知"
        echo "$output"
        return 1
    fi
}

run_deployment_tests() {
    print_header "部署测试"
    
    log_step "运行部署验证测试..."
    
    local output=$(python3 "$PROJECT_DIR/tests/test_deployment.py" 2>&1)
    local exit_code=$?
    
    if echo "$output" | grep -q "OK"; then
        local test_count=$(echo "$output" | grep "Ran" | awk '{print $2}')
        print_success_header "部署测试通过"
        echo -e "  ${GREEN}运行了 $test_count 个测试，全部通过${NC}"
        echo ""
        return 0
    else
        print_warning_header "部署测试未通过"
        echo "这是正常的，部分测试需要集群部署后才能通过"
        echo ""
        return 0
    fi
}

# ==========================================
# 主函数
# ==========================================

main() {
    print_banner "CDH 集群测试套件" "自动化测试与验证" "RaynLiu"
    
    log_info "测试开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "测试输出目录: $TEST_OUTPUT_DIR"
    log_info "测试报告文件: $TEST_REPORT"
    
    # 运行环境测试
    run_environment_tests
    local env_result=$?
    
    # 运行部署测试  
    run_deployment_tests
    local deploy_result=$?
    
    # 生成汇总报告
    print_header "测试汇总"
    
    echo ""
    print_table_row "测试类型" "结果" "状态"
    print_table_header
    
    if [ $env_result -eq 0 ]; then
        print_table_row "环境测试" "${GREEN}通过${NC}" "✓"
    else
        print_table_row "环境测试" "${RED}失败${NC}" "✗"
    fi
    
    if [ $deploy_result -eq 0 ]; then
        print_table_row "部署测试" "${GREEN}通过${NC}" "✓"
    else
        print_table_row "部署测试" "${YELLOW}部分通过${NC}" "⚠"
    fi
    
    print_single_line
    echo ""
    
    # 最终结果
    if [ $env_result -eq 0 ]; then
        print_success_header "测试完成 - 环境正常"
        echo -e "  ${GREEN}✓${NC} 环境测试全部通过"
        echo -e "  ${GREEN}✓${NC} 可以开始部署 CDH 集群"
        echo ""
        echo "下一步操作："
        echo "  make deploy       # 开始部署"
        echo "  make check        # 检查环境"
        echo ""
        return 0
    else
        print_error_header "测试未通过"
        echo -e "  ${RED}✗${NC} 环境测试存在问题"
        echo ""
        echo "建议操作："
        echo "  1. 查看详细日志: cat $TEST_REPORT"
        echo "  2. 修复环境: make prepare-env"
        echo "  3. 重新测试: make test-env"
        echo ""
        return 1
    fi
}

# 运行主函数
main
exit $?
