#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
创建管理员账户脚本
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import db, create_app
from app.models import User

def create_admin_user():
    """创建管理员账户"""
    app = create_app()
    
    with app.app_context():
        # 检查是否已存在管理员
        existing_admin = User.query.filter_by(phone='admin').first()
        if existing_admin:
            print("管理员账户已存在")
            print(f"手机号: {existing_admin.phone}")
            print(f"昵称: {existing_admin.nickname}")
            print(f"快手ID: {existing_admin.kuaishouId}")
            return
        
        # 创建管理员账户
        admin_user = User(
            nickname='超级管理员',
            kuaishouId='admin001',
            phone='admin',  # 使用特殊手机号
            points=1000,
            is_admin=True,
            addresses=[]
        )
        
        # 设置密码为 'Eternalmoon.com1'
        admin_user.set_password('Eternalmoon.com1')
        
        db.session.add(admin_user)
        db.session.commit()
        
        print("✅ 管理员账户创建成功！")
        print("=" * 40)
        print("登录信息:")
        print("手机号: admin")
        print("密码: Eternalmoon.com1")
        print("=" * 40)

if __name__ == '__main__':
    create_admin_user()