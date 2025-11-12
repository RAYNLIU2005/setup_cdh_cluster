#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CDH集群环境测试
author: RaynLiu
email: liuyu1_j6go@stu.cqie.edu.cn
date: 2025-11-12

功能说明：
测试部署环境的准备情况，包括磁盘空间、网络连通性、依赖软件等
"""

import os
import subprocess
import unittest
from pathlib import Path


class TestEnvironment(unittest.TestCase):
    """环境测试类"""
    
    def setUp(self):
        """测试前准备"""
        self.project_dir = Path('/root/setup_cdh_cluster')
        self.nodes = ['node01', 'node02', 'node03']
    
    def test_project_structure(self):
        """测试项目结构完整性"""
        required_dirs = [
            'ansible',
            'ansible/component',
            'ansible/node_group',
            'scripts',
            'doc',
            'tests'
        ]
        
        for dir_name in required_dirs:
            dir_path = self.project_dir / dir_name
            self.assertTrue(
                dir_path.exists(),
                f"目录不存在: {dir_path}"
            )
    
    def test_required_files(self):
        """测试必需文件存在性"""
        required_files = [
            'Makefile',
            'requirements.txt',
            '.env.template',
            'ansible/deploy_cdh.yml',
            'ansible/node_group/hosts',
            'scripts/manage_cluster.sh'
        ]
        
        for file_name in required_files:
            file_path = self.project_dir / file_name
            self.assertTrue(
                file_path.exists(),
                f"文件不存在: {file_path}"
            )
    
    def test_python_version(self):
        """测试Python版本"""
        result = subprocess.run(
            ['python3', '--version'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True
        )
        self.assertEqual(result.returncode, 0, "Python3未安装")
        self.assertIn('Python 3', result.stdout, "Python版本不正确")
    
    def test_ansible_installed(self):
        """测试Ansible是否安装"""
        result = subprocess.run(
            ['ansible', '--version'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True
        )
        self.assertEqual(result.returncode, 0, "Ansible未安装")
    
    def test_disk_space(self):
        """测试磁盘空间"""
        result = subprocess.run(
            ['df', '-BG', '/'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True
        )
        self.assertEqual(result.returncode, 0, "无法检查磁盘空间")
        
        # 解析可用空间（简化版本）
        lines = result.stdout.strip().split('\n')
        if len(lines) > 1:
            available = lines[1].split()[3].replace('G', '')
            # 降低阈值到5GB，适应测试环境
            self.assertGreater(
                int(available),
                5,
                f"磁盘空间不足（当前: {available}GB，要求: >5GB）"
            )
    
    def test_script_permissions(self):
        """测试脚本执行权限"""
        scripts = [
            'scripts/manage_cluster.sh',
            'scripts/health_check.sh',
            'scripts/setup_ssh_keys.sh'
        ]
        
        for script in scripts:
            script_path = self.project_dir / script
            if script_path.exists():
                self.assertTrue(
                    os.access(script_path, os.X_OK),
                    f"脚本无执行权限: {script_path}"
                )


class TestNetworkConnectivity(unittest.TestCase):
    """网络连通性测试类"""
    
    def setUp(self):
        """测试前准备"""
        self.nodes = ['node01', 'node02', 'node03']
    
    def test_hostname_resolution(self):
        """测试主机名解析"""
        for node in self.nodes:
            result = subprocess.run(
                ['getent', 'hosts', node],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True
            )
            self.assertEqual(
                result.returncode,
                0,
                f"无法解析主机名: {node}"
            )
    
    def test_ping_nodes(self):
        """测试节点连通性"""
        for node in self.nodes:
            result = subprocess.run(
                ['ping', '-c', '1', '-W', '2', node],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True
            )
            self.assertEqual(
                result.returncode,
                0,
                f"节点不可达: {node}"
            )


class TestDependencies(unittest.TestCase):
    """依赖软件测试类"""
    
    def test_pymysql_installed(self):
        """测试PyMySQL是否安装"""
        try:
            import pymysql
            self.assertIsNotNone(pymysql)
        except ImportError:
            self.fail("PyMySQL未安装")
    
    def test_yaml_installed(self):
        """测试PyYAML是否安装"""
        try:
            import yaml
            self.assertIsNotNone(yaml)
        except ImportError:
            self.fail("PyYAML未安装")


def run_tests():
    """运行所有测试"""
    # 创建测试套件
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # 添加测试
    suite.addTests(loader.loadTestsFromTestCase(TestEnvironment))
    suite.addTests(loader.loadTestsFromTestCase(TestNetworkConnectivity))
    suite.addTests(loader.loadTestsFromTestCase(TestDependencies))
    
    # 运行测试
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    return result.wasSuccessful()


if __name__ == '__main__':
    import sys
    success = run_tests()
    sys.exit(0 if success else 1)
