#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CDH集群部署功能测试
author: RaynLiu
email: liuyu1_j6go@stu.cqie.edu.cn
date: 2025-11-12

功能说明：
测试部署后的服务状态和功能
"""

import subprocess
import unittest
import time


class TestServices(unittest.TestCase):
    """服务状态测试类"""
    
    def setUp(self):
        """测试前准备"""
        self.master_node = 'node01'
        self.slave_nodes = ['node02', 'node03']
    
    def test_mysql_service(self):
        """测试MySQL服务状态"""
        result = subprocess.run(
            ['ssh', self.master_node, 'systemctl', 'is-active', 'mysqld'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True
        )
        self.assertEqual(
            result.stdout.strip(),
            'active',
            "MySQL服务未运行"
        )
    
    def test_httpd_service(self):
        """测试httpd服务状态"""
        result = subprocess.run(
            ['ssh', self.master_node, 'systemctl', 'is-active', 'httpd'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True
        )
        self.assertEqual(
            result.stdout.strip(),
            'active',
            "httpd服务未运行"
        )
    
    def test_cm_server_service(self):
        """测试CM Server服务状态"""
        result = subprocess.run(
            ['ssh', self.master_node, 'systemctl', 'is-active', 'cloudera-scm-server'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True
        )
        self.assertEqual(
            result.stdout.strip(),
            'active',
            "CM Server服务未运行"
        )
    
    def test_cm_agent_on_master(self):
        """测试Master节点CM Agent"""
        result = subprocess.run(
            ['ssh', self.master_node, 'systemctl', 'is-active', 'cloudera-scm-agent'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True
        )
        self.assertEqual(
            result.stdout.strip(),
            'active',
            f"{self.master_node} CM Agent未运行"
        )
    
    def test_cm_agent_on_slaves(self):
        """测试Slave节点CM Agent"""
        for node in self.slave_nodes:
            with self.subTest(node=node):
                result = subprocess.run(
                    ['ssh', node, 'systemctl', 'is-active', 'cloudera-scm-agent'],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    universal_newlines=True,
                    timeout=10
                )
                self.assertEqual(
                    result.stdout.strip(),
                    'active',
                    f"{node} CM Agent未运行"
                )


class TestPorts(unittest.TestCase):
    """端口监听测试类"""
    
    def setUp(self):
        """测试前准备"""
        self.master_node = 'node01'
    
    def test_mysql_port(self):
        """测试MySQL端口3306"""
        result = subprocess.run(
            ['ssh', self.master_node, 'netstat', '-tlnp', '|', 'grep', '3306'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
            shell=True
        )
        self.assertIn('3306', result.stdout, "MySQL端口3306未监听")
    
    def test_cm_server_port(self):
        """测试CM Server端口7180"""
        result = subprocess.run(
            ['ssh', self.master_node, 'netstat', '-tlnp', '|', 'grep', '7180'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
            shell=True
        )
        self.assertIn('7180', result.stdout, "CM Server端口7180未监听")
    
    def test_httpd_port(self):
        """测试httpd端口80"""
        result = subprocess.run(
            ['ssh', self.master_node, 'netstat', '-tlnp', '|', 'grep', ':80'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
            shell=True
        )
        self.assertIn(':80', result.stdout, "httpd端口80未监听")


class TestInstallation(unittest.TestCase):
    """安装验证测试类"""
    
    def setUp(self):
        """测试前准备"""
        self.nodes = ['node01', 'node02', 'node03']
    
    def test_java_installation(self):
        """测试Java安装"""
        for node in self.nodes:
            with self.subTest(node=node):
                result = subprocess.run(
                    ['ssh', node, 'java', '-version'],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    universal_newlines=True
                )
                self.assertEqual(
                    result.returncode,
                    0,
                    f"{node} Java未安装"
                )
    
    def test_scala_installation(self):
        """测试Scala安装"""
        for node in self.nodes:
            with self.subTest(node=node):
                result = subprocess.run(
                    ['ssh', node, 'scala', '-version'],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    universal_newlines=True
                )
                self.assertEqual(
                    result.returncode,
                    0,
                    f"{node} Scala未安装"
                )
    
    def test_python3_installation(self):
        """测试Python3安装"""
        for node in self.nodes:
            with self.subTest(node=node):
                result = subprocess.run(
                    ['ssh', node, 'python3', '--version'],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    universal_newlines=True
                )
                self.assertEqual(
                    result.returncode,
                    0,
                    f"{node} Python3未安装"
                )


def run_tests():
    """运行所有测试"""
    # 创建测试套件
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # 添加测试
    suite.addTests(loader.loadTestsFromTestCase(TestServices))
    suite.addTests(loader.loadTestsFromTestCase(TestPorts))
    suite.addTests(loader.loadTestsFromTestCase(TestInstallation))
    
    # 运行测试
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    return result.wasSuccessful()


if __name__ == '__main__':
    import sys
    success = run_tests()
    sys.exit(0 if success else 1)
