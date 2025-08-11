#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
增强版管理员账户创建脚本 - 自动处理数据库初始化
"""
import sys
import os
import sqlite3
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

def check_database_exists():
    """检查数据库文件是否存在"""
    db_path = project_root / "app.db"
    return db_path.exists()

def check_tables_exist():
    """检查数据库表是否存在"""
    db_path = project_root / "app.db"
    if not db_path.exists():
        return False
    
    try:
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()
        
        # 检查user表是否存在
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='user'")
        result = cursor.fetchone()
        conn.close()
        
        return result is not None
    except Exception as e:
        print(f"检查表时出错: {e}")
        return False

def init_database():
    """初始化数据库"""
    print("🔄 正在初始化数据库...")
    
    try:
        from app import create_app, db
        
        app = create_app()
        with app.app_context():
            # 创建所有表
            db.create_all()
            print("✅ 数据库表创建成功")
            return True
    except Exception as e:
        print(f"❌ 数据库初始化失败: {e}")
        return False

def create_admin_user():
    """创建管理员账户"""
    try:
        from app import create_app, db
        from app.models import User
        
        app = create_app()
        with app.app_context():
            # 检查是否已存在管理员
            existing_admin = User.query.filter_by(phone='admin').first()
            if existing_admin:
                print("✅ 管理员账户已存在")
                print("=" * 40)
                print("登录信息:")
                print("手机号: admin")
                print("密码: Eternalmoon.com1")
                print("=" * 40)
                return True
            
            # 创建管理员账户
            admin_user = User(
                nickname='超级管理员',
                kuaishouId='admin001',
                phone='admin',
                points=1000,
                is_admin=True,
                addresses=[]
            )
            
            # 设置密码
            admin_user.set_password('Eternalmoon.com1')
            
            db.session.add(admin_user)
            db.session.commit()
            
            print("✅ 管理员账户创建成功！")
            print("=" * 40)
            print("登录信息:")
            print("手机号: admin")
            print("密码: Eternalmoon.com1")
            print("=" * 40)
            return True
            
    except Exception as e:
        print(f"❌ 创建管理员失败: {e}")
        return False

def main():
    """主函数"""
    print("🚀 启动管理员账户创建工具...")
    
    # 检查工作目录
    if not (project_root / "app").exists():
        print(f"❌ 项目结构不正确，请在正确目录运行脚本")
        print(f"当前项目根目录: {project_root}")
        sys.exit(1)
    
    # 检查数据库是否存在
    if not check_database_exists():
        print("⚠️  数据库文件不存在，正在创建...")
        if not init_database():
            print("❌ 数据库初始化失败")
            sys.exit(1)
    
    # 检查表是否存在
    if not check_tables_exist():
        print("⚠️  数据库表不存在，正在创建...")
        if not init_database():
            print("❌ 数据库表创建失败")
            sys.exit(1)
    
    # 创建管理员账户
    if create_admin_user():
        print("🎉 管理员账户处理完成！")
    else:
        print("❌ 管理员账户创建失败")
        sys.exit(1)

if __name__ == '__main__':
    main()