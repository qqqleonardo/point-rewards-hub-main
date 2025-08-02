#!/usr/bin/env python3
"""
数据库查看工具脚本
使用方法：python view_data.py [table_name]
"""

import sys
import sqlite3
from datetime import datetime
import os

# 数据库文件路径
DB_PATH = 'app.db'

def connect_db():
    """连接数据库"""
    if not os.path.exists(DB_PATH):
        print(f"错误: 数据库文件 {DB_PATH} 不存在")
        sys.exit(1)
    
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # 使查询结果可以按列名访问
    return conn

def show_tables():
    """显示所有表"""
    conn = connect_db()
    cursor = conn.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = cursor.fetchall()
    conn.close()
    
    print("数据库中的表:")
    for table in tables:
        print(f"  - {table[0]}")

def show_table_schema(table_name):
    """显示表结构"""
    conn = connect_db()
    cursor = conn.execute(f"PRAGMA table_info({table_name});")
    columns = cursor.fetchall()
    conn.close()
    
    print(f"\n表 '{table_name}' 的结构:")
    print("列名".ljust(20) + "类型".ljust(15) + "非空".ljust(8) + "默认值")
    print("-" * 60)
    for col in columns:
        print(f"{col[1]:<20} {col[2]:<15} {'YES' if col[3] else 'NO':<8} {col[4] or ''}")

def show_table_data(table_name, limit=10):
    """显示表数据"""
    conn = connect_db()
    
    # 获取表中记录总数
    count_cursor = conn.execute(f"SELECT COUNT(*) FROM {table_name};")
    total_count = count_cursor.fetchone()[0]
    
    # 获取数据
    cursor = conn.execute(f"SELECT * FROM {table_name} LIMIT {limit};")
    rows = cursor.fetchall()
    
    if not rows:
        print(f"表 '{table_name}' 中没有数据")
        conn.close()
        return
    
    # 显示列名
    column_names = [description[0] for description in cursor.description]
    print(f"\n表 '{table_name}' 的数据 (显示前{limit}条，总共{total_count}条):")
    print("-" * 80)
    
    # 显示表头
    header = " | ".join([col[:15] for col in column_names])
    print(header)
    print("-" * len(header))
    
    # 显示数据
    for row in rows:
        row_data = " | ".join([str(row[col])[:15] if row[col] is not None else "NULL" for col in column_names])
        print(row_data)
    
    conn.close()

def show_users_summary():
    """用户数据汇总"""
    conn = connect_db()
    
    print("\n=== 用户数据汇总 ===")
    
    # 用户总数
    cursor = conn.execute("SELECT COUNT(*) FROM users;")
    user_count = cursor.fetchone()[0]
    print(f"总用户数: {user_count}")
    
    # 活跃用户（有积分的用户）
    cursor = conn.execute("SELECT COUNT(*) FROM users WHERE points > 0;")
    active_users = cursor.fetchone()[0]
    print(f"有积分用户: {active_users}")
    
    # 积分统计
    cursor = conn.execute("SELECT SUM(points), AVG(points), MAX(points) FROM users;")
    points_stats = cursor.fetchone()
    print(f"总积分: {points_stats[0] or 0}")
    print(f"平均积分: {points_stats[1]:.2f if points_stats[1] else 0}")
    print(f"最高积分: {points_stats[2] or 0}")
    
    conn.close()

def show_redemptions_summary():
    """兑换记录汇总"""
    conn = connect_db()
    
    print("\n=== 兑换记录汇总 ===")
    
    # 兑换总数
    cursor = conn.execute("SELECT COUNT(*) FROM redemptions;")
    total_redemptions = cursor.fetchone()[0]
    print(f"总兑换次数: {total_redemptions}")
    
    # 按状态统计
    cursor = conn.execute("SELECT status, COUNT(*) FROM redemptions GROUP BY status;")
    status_stats = cursor.fetchall()
    print("按状态统计:")
    for status, count in status_stats:
        print(f"  {status}: {count}")
    
    # 最近兑换
    cursor = conn.execute("""
        SELECT r.created_at, u.username, p.name 
        FROM redemptions r 
        JOIN users u ON r.user_id = u.id 
        JOIN prizes p ON r.prize_id = p.id 
        ORDER BY r.created_at DESC 
        LIMIT 5;
    """)
    recent_redemptions = cursor.fetchall()
    
    print("\n最近5次兑换:")
    for redemption in recent_redemptions:
        print(f"  {redemption[0]} - {redemption[1]} 兑换了 {redemption[2]}")
    
    conn.close()

def main():
    if len(sys.argv) > 1:
        table_name = sys.argv[1]
        
        if table_name == "--help" or table_name == "-h":
            print("用法:")
            print("  python view_data.py              # 显示所有表")
            print("  python view_data.py users        # 显示users表数据") 
            print("  python view_data.py prizes       # 显示prizes表数据")
            print("  python view_data.py redemptions  # 显示redemptions表数据")
            print("  python view_data.py summary      # 显示数据汇总")
            return
        
        if table_name == "summary":
            show_users_summary()
            show_redemptions_summary()
            return
        
        # 检查表是否存在
        conn = connect_db()
        cursor = conn.execute("SELECT name FROM sqlite_master WHERE type='table' AND name=?;", (table_name,))
        if not cursor.fetchone():
            print(f"错误: 表 '{table_name}' 不存在")
            show_tables()
            conn.close()
            return
        conn.close()
        
        show_table_schema(table_name)
        show_table_data(table_name)
    else:
        show_tables()
        print("\n使用 'python view_data.py [table_name]' 查看具体表的数据")
        print("使用 'python view_data.py summary' 查看数据汇总")
        print("使用 'python view_data.py --help' 查看帮助")

if __name__ == "__main__":
    main()