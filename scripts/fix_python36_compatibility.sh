#!/bin/bash
# 修复 Python 3.6 兼容性问题
# author: RaynLiu
# email: liuyu1_j6go@stu.cqie.edu.cn

echo "正在修复 Python 3.6 兼容性问题..."

PROJECT_DIR=/root/setup_cdh_cluster

# 修复 test_environment.py
echo "修复 tests/test_environment.py..."
sed -i 's/capture_output=True,/stdout=subprocess.PIPE,\n            stderr=subprocess.PIPE,/g' "$PROJECT_DIR/tests/test_environment.py"
sed -i 's/text=True/universal_newlines=True/g' "$PROJECT_DIR/tests/test_environment.py"

# 修复 test_deployment.py
echo "修复 tests/test_deployment.py..."
sed -i 's/capture_output=True,/stdout=subprocess.PIPE,\n            stderr=subprocess.PIPE,/g' "$PROJECT_DIR/tests/test_deployment.py"
sed -i 's/text=True/universal_newlines=True/g' "$PROJECT_DIR/tests/test_deployment.py"

echo "✓ 修复完成"
echo ""
echo "请重新运行测试："
echo "  make test-env"
echo "  make test-full"
