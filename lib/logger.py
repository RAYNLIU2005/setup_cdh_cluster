#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CDH集群部署系统 - 统一日志模块
author: RaynLiu
email: liuyu1_j6go@stu.cqie.edu.cn
date: 2025-11-12

功能说明：
提供统一的日志记录功能，支持控制台和文件输出
支持日志分级、颜色输出、日志轮转等功能
"""

import logging
import os
import sys
from logging.handlers import RotatingFileHandler
from datetime import datetime
from pathlib import Path


class ColorFormatter(logging.Formatter):
    """
    彩色日志格式化器
    为不同级别的日志添加颜色，便于区分
    """
    
    # ANSI颜色代码
    COLORS = {
        'DEBUG': '\033[0;36m',    # 青色
        'INFO': '\033[0;32m',     # 绿色
        'WARNING': '\033[1;33m',  # 黄色
        'ERROR': '\033[0;31m',    # 红色
        'CRITICAL': '\033[1;35m', # 紫色
    }
    RESET = '\033[0m'
    
    def format(self, record):
        """格式化日志记录"""
        # 添加颜色
        if record.levelname in self.COLORS:
            record.levelname = (
                f"{self.COLORS[record.levelname]}"
                f"{record.levelname}"
                f"{self.RESET}"
            )
        return super().format(record)


class CDHLogger:
    """
    CDH集群部署系统统一日志类
    
    功能特性：
    1. 支持控制台和文件双输出
    2. 自动日志轮转（大小限制）
    3. 彩色控制台输出
    4. 统一日志格式
    5. 支持多个日志记录器
    """
    
    # 日志格式
    LOG_FORMAT = (
        '[%(asctime)s] '
        '[%(levelname)s] '
        '[%(name)s:%(lineno)d] '
        '- %(message)s'
    )
    
    # 日期格式
    DATE_FORMAT = '%Y-%m-%d %H:%M:%S'
    
    # 默认日志文件
    DEFAULT_LOG_FILE = '/var/log/cdh_deploy.log'
    
    # 日志文件最大大小（100MB）
    MAX_BYTES = 100 * 1024 * 1024
    
    # 保留的备份文件数量
    BACKUP_COUNT = 5
    
    def __init__(
        self,
        name: str,
        log_file: str = None,
        level: str = 'INFO',
        console: bool = True,
        file_output: bool = True
    ):
        """
        初始化日志记录器
        
        参数:
            name: 日志记录器名称
            log_file: 日志文件路径（默认使用DEFAULT_LOG_FILE）
            level: 日志级别（DEBUG, INFO, WARNING, ERROR, CRITICAL）
            console: 是否输出到控制台
            file_output: 是否输出到文件
        """
        self.name = name
        self.log_file = log_file or self.DEFAULT_LOG_FILE
        self.level = getattr(logging, level.upper(), logging.INFO)
        
        # 创建日志记录器
        self.logger = logging.getLogger(name)
        self.logger.setLevel(self.level)
        
        # 避免重复添加处理器
        if self.logger.handlers:
            self.logger.handlers.clear()
        
        # 添加控制台处理器
        if console:
            self._add_console_handler()
        
        # 添加文件处理器
        if file_output:
            self._add_file_handler()
    
    def _add_console_handler(self):
        """添加控制台处理器（带颜色）"""
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(self.level)
        
        # 使用彩色格式化器
        color_formatter = ColorFormatter(
            self.LOG_FORMAT,
            datefmt=self.DATE_FORMAT
        )
        console_handler.setFormatter(color_formatter)
        
        self.logger.addHandler(console_handler)
    
    def _add_file_handler(self):
        """添加文件处理器（带轮转）"""
        # 确保日志目录存在
        log_dir = Path(self.log_file).parent
        log_dir.mkdir(parents=True, exist_ok=True)
        
        # 创建轮转文件处理器
        file_handler = RotatingFileHandler(
            self.log_file,
            maxBytes=self.MAX_BYTES,
            backupCount=self.BACKUP_COUNT,
            encoding='utf-8'
        )
        file_handler.setLevel(self.level)
        
        # 使用标准格式化器（文件不需要颜色）
        file_formatter = logging.Formatter(
            self.LOG_FORMAT,
            datefmt=self.DATE_FORMAT
        )
        file_handler.setFormatter(file_formatter)
        
        self.logger.addHandler(file_handler)
    
    def debug(self, message: str):
        """记录DEBUG级别日志"""
        self.logger.debug(message)
    
    def info(self, message: str):
        """记录INFO级别日志"""
        self.logger.info(message)
    
    def warning(self, message: str):
        """记录WARNING级别日志"""
        self.logger.warning(message)
    
    def error(self, message: str):
        """记录ERROR级别日志"""
        self.logger.error(message)
    
    def critical(self, message: str):
        """记录CRITICAL级别日志"""
        self.logger.critical(message)
    
    def exception(self, message: str):
        """记录异常信息（包含堆栈跟踪）"""
        self.logger.exception(message)
    
    def section(self, title: str):
        """记录分节标题（便于日志阅读）"""
        separator = '=' * 60
        self.logger.info(separator)
        self.logger.info(f"  {title}")
        self.logger.info(separator)
    
    def step(self, step_num: int, total_steps: int, description: str):
        """记录步骤信息"""
        self.logger.info(f"[步骤 {step_num}/{total_steps}] {description}")


def get_logger(
    name: str = 'CDH',
    log_file: str = None,
    level: str = 'INFO',
    console: bool = True,
    file_output: bool = True
) -> CDHLogger:
    """
    获取日志记录器实例
    
    参数:
        name: 日志记录器名称
        log_file: 日志文件路径
        level: 日志级别
        console: 是否输出到控制台
        file_output: 是否输出到文件
    
    返回:
        CDHLogger实例
    """
    return CDHLogger(
        name=name,
        log_file=log_file,
        level=level,
        console=console,
        file_output=file_output
    )


# ==========================================
# 使用示例
# ==========================================
if __name__ == '__main__':
    # 创建日志记录器
    logger = get_logger('CDH.Test', level='DEBUG')
    
    # 记录不同级别的日志
    logger.section('日志模块测试')
    logger.debug('这是DEBUG级别的日志')
    logger.info('这是INFO级别的日志')
    logger.warning('这是WARNING级别的日志')
    logger.error('这是ERROR级别的日志')
    logger.critical('这是CRITICAL级别的日志')
    
    # 记录步骤
    logger.section('部署步骤示例')
    logger.step(1, 5, '检查环境')
    logger.step(2, 5, '安装依赖')
    logger.step(3, 5, '配置服务')
    logger.step(4, 5, '启动服务')
    logger.step(5, 5, '验证部署')
    
    # 测试异常记录
    try:
        1 / 0
    except Exception:
        logger.exception('捕获到异常')
    
    logger.info('日志模块测试完成')
