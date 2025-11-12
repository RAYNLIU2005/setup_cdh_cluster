#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CDH集群部署系统 - 配置管理模块
author: RaynLiu
email: liuyu1_j6go@stu.cqie.edu.cn
date: 2025-11-12

功能说明：
提供统一的配置管理功能，支持从环境变量和.env文件读取配置
"""

import os
from pathlib import Path
from typing import Any, Optional
from dotenv import load_dotenv


class Config:
    """
    配置管理类
    
    功能特性：
    1. 自动加载.env文件
    2. 支持环境变量覆盖
    3. 提供类型转换
    4. 提供默认值
    """
    
    # 项目根目录
    PROJECT_ROOT = Path(__file__).parent.parent
    
    # .env文件路径
    ENV_FILE = PROJECT_ROOT / '.env'
    
    def __init__(self, env_file: Optional[str] = None):
        """
        初始化配置管理器
        
        参数:
            env_file: .env文件路径（可选）
        """
        # 加载.env文件
        env_path = env_file or self.ENV_FILE
        if Path(env_path).exists():
            load_dotenv(env_path)
    
    @staticmethod
    def get(key: str, default: Any = None, cast_type: type = str) -> Any:
        """
        获取配置值
        
        参数:
            key: 配置键名
            default: 默认值
            cast_type: 类型转换（str, int, bool等）
        
        返回:
            配置值
        """
        value = os.getenv(key, default)
        
        if value is None:
            return default
        
        # 类型转换
        try:
            if cast_type == bool:
                # 布尔值特殊处理
                return str(value).lower() in ('true', '1', 'yes', 'on')
            elif cast_type == int:
                return int(value)
            elif cast_type == float:
                return float(value)
            else:
                return cast_type(value)
        except (ValueError, TypeError):
            return default
    
    # ==========================================
    # 项目基本配置
    # ==========================================
    
    @property
    def project_name(self) -> str:
        """项目名称"""
        return self.get('PROJECT_NAME', 'setup_cdh_cluster')
    
    @property
    def project_dir(self) -> str:
        """项目目录"""
        return self.get('PROJECT_DIR', '/root/setup_cdh_cluster')
    
    @property
    def author_name(self) -> str:
        """作者名称"""
        return self.get('AUTHOR_NAME', 'RaynLiu')
    
    @property
    def author_email(self) -> str:
        """作者邮箱"""
        return self.get('AUTHOR_EMAIL', 'liuyu1_j6go@stu.cqie.edu.cn')
    
    # ==========================================
    # 集群节点配置
    # ==========================================
    
    @property
    def master_node(self) -> str:
        """主节点"""
        return self.get('MASTER_NODE', 'node01')
    
    @property
    def master_ip(self) -> str:
        """主节点IP"""
        return self.get('MASTER_IP', '192.168.56.151')
    
    @property
    def slave_nodes(self) -> list:
        """从节点列表"""
        return [
            self.get('SLAVE_NODE_1', 'node02'),
            self.get('SLAVE_NODE_2', 'node03')
        ]
    
    @property
    def all_nodes(self) -> list:
        """所有节点"""
        return [self.master_node] + self.slave_nodes
    
    # ==========================================
    # MySQL配置
    # ==========================================
    
    @property
    def mysql_root_password(self) -> str:
        """MySQL root密码"""
        return self.get('MYSQL_ROOT_PASSWORD', 'Cloudera!20200801')
    
    @property
    def mysql_host(self) -> str:
        """MySQL主机"""
        return self.get('MYSQL_HOST', 'localhost')
    
    @property
    def mysql_port(self) -> int:
        """MySQL端口"""
        return self.get('MYSQL_PORT', 3306, int)
    
    # ==========================================
    # CDH版本配置
    # ==========================================
    
    @property
    def cdh_version(self) -> str:
        """CDH版本"""
        return self.get('CDH_VERSION', '6.2.0')
    
    @property
    def cm_version(self) -> str:
        """Cloudera Manager版本"""
        return self.get('CM_VERSION', '6.2.0')
    
    @property
    def java_version(self) -> str:
        """Java版本"""
        return self.get('JAVA_VERSION', '8u261')
    
    # ==========================================
    # 路径配置
    # ==========================================
    
    @property
    def base_file_path(self) -> str:
        """基础文件路径"""
        return self.get('BASE_FILE_PATH', '/opt/base_file')
    
    @property
    def package_path(self) -> str:
        """安装包路径"""
        return self.get('PACKAGE_PATH', '/opt/setup_cdh')
    
    # ==========================================
    # 日志配置
    # ==========================================
    
    @property
    def log_file(self) -> str:
        """日志文件路径"""
        return self.get('LOG_FILE', '/var/log/cdh_deploy.log')
    
    @property
    def log_level(self) -> str:
        """日志级别"""
        return self.get('LOG_LEVEL', 'INFO')
    
    @property
    def log_max_size(self) -> str:
        """日志最大大小"""
        return self.get('LOG_MAX_SIZE', '100M')
    
    # ==========================================
    # 部署配置
    # ==========================================
    
    @property
    def deploy_timeout(self) -> int:
        """部署超时时间（秒）"""
        return self.get('DEPLOY_TIMEOUT', 3600, int)
    
    @property
    def auto_cleanup(self) -> bool:
        """是否自动清理"""
        return self.get('AUTO_CLEANUP', True, bool)
    
    @property
    def disk_check_enabled(self) -> bool:
        """是否启用磁盘检查"""
        return self.get('DISK_CHECK_ENABLED', True, bool)
    
    @property
    def min_disk_space_gb(self) -> int:
        """最小磁盘空间（GB）"""
        return self.get('MIN_DISK_SPACE_GB', 25, int)
    
    # ==========================================
    # 服务端口配置
    # ==========================================
    
    @property
    def cm_server_port(self) -> int:
        """CM Server端口"""
        return self.get('CM_SERVER_PORT', 7180, int)
    
    @property
    def cm_agent_port(self) -> int:
        """CM Agent端口"""
        return self.get('CM_AGENT_PORT', 7182, int)
    
    # ==========================================
    # Docker配置
    # ==========================================
    
    @property
    def enable_docker(self) -> bool:
        """是否启用Docker"""
        return self.get('ENABLE_DOCKER', False, bool)
    
    @property
    def docker_image_tag(self) -> str:
        """Docker镜像标签"""
        return self.get('DOCKER_IMAGE_TAG', 'latest')
    
    # ==========================================
    # 辅助方法
    # ==========================================
    
    def to_dict(self) -> dict:
        """导出所有配置为字典"""
        return {
            'project_name': self.project_name,
            'project_dir': self.project_dir,
            'author_name': self.author_name,
            'author_email': self.author_email,
            'master_node': self.master_node,
            'master_ip': self.master_ip,
            'slave_nodes': self.slave_nodes,
            'all_nodes': self.all_nodes,
            'mysql_root_password': '***',  # 隐藏密码
            'mysql_host': self.mysql_host,
            'mysql_port': self.mysql_port,
            'cdh_version': self.cdh_version,
            'cm_version': self.cm_version,
            'java_version': self.java_version,
            'log_file': self.log_file,
            'log_level': self.log_level,
            'cm_server_port': self.cm_server_port,
            'cm_agent_port': self.cm_agent_port,
        }
    
    def validate(self) -> bool:
        """验证配置有效性"""
        errors = []
        
        # 检查必需配置
        if not self.master_node:
            errors.append("MASTER_NODE未配置")
        
        if not self.master_ip:
            errors.append("MASTER_IP未配置")
        
        if not self.slave_nodes:
            errors.append("SLAVE_NODE未配置")
        
        # 检查端口范围
        if not (1 <= self.mysql_port <= 65535):
            errors.append(f"MySQL端口无效: {self.mysql_port}")
        
        if not (1 <= self.cm_server_port <= 65535):
            errors.append(f"CM Server端口无效: {self.cm_server_port}")
        
        # 如果有错误，打印并返回False
        if errors:
            print("配置验证失败:")
            for error in errors:
                print(f"  - {error}")
            return False
        
        return True


# ==========================================
# 全局配置实例
# ==========================================
config = Config()


# ==========================================
# 使用示例
# ==========================================
if __name__ == '__main__':
    # 创建配置实例
    cfg = Config()
    
    # 验证配置
    if cfg.validate():
        print("✓ 配置验证通过")
    
    # 打印配置
    print("\n配置信息:")
    print("=" * 60)
    for key, value in cfg.to_dict().items():
        print(f"{key:20s}: {value}")
    print("=" * 60)
