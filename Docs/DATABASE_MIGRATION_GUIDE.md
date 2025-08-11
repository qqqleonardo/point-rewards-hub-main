# 数据库变更操作指南

本文档详细说明如何安全地进行数据库结构变更，包括添加字段、修改表结构等操作。

## 目录
1. [数据库迁移概述](#数据库迁移概述)
2. [使用 manage.sh 进行数据库管理](#使用-managesh-进行数据库管理)
3. [手动迁移操作](#手动迁移操作)
4. [常见场景示例](#常见场景示例)
5. [故障处理](#故障处理)

## 数据库迁移概述

本项目使用 **Flask-Migrate** (基于 Alembic) 进行数据库版本控制和迁移管理。

### 当前环境
- 数据库: SQLite
- ORM: SQLAlchemy 
- 迁移工具: Flask-Migrate
- 迁移文件位置: `/opt/point-rewards/point-rewards-backend/migrations/versions/`
- 统一管理工具: manage.sh (推荐)

## 使用 manage.sh 进行数据库管理

### 快速数据库操作 (推荐)
```bash
# 查看数据库状态和数据
bash manage.sh view-data summary        # 数据汇总
bash manage.sh view-data users          # 用户表
bash manage.sh view-data prizes         # 奖品表

# 数据库维护
sudo bash manage.sh backup              # 备份数据库
sudo bash manage.sh fix-db              # 修复数据库问题
sudo bash manage.sh init-db             # 初始化数据库
```

### 数据库问题处理流程
```bash
# 1. 检查当前状态
bash manage.sh view-data summary

# 2. 备份数据库
sudo bash manage.sh backup

# 3. 修复数据库问题
sudo bash manage.sh fix-db

# 4. 验证修复结果
bash manage.sh view-data summary
```

## 手动迁移操作

### 准备工作

#### 1. 使用 manage.sh 备份数据库 (推荐)
```bash
# 自动备份数据库
sudo bash manage.sh backup
```

#### 2. 手动备份 (备选方案)
```bash
# 进入后端目录
cd /opt/point-rewards/point-rewards-backend

# 创建数据库备份
BACKUP_FILE="app_backup_$(date +%Y%m%d_%H%M%S).db"
cp app.db "$BACKUP_FILE"
echo "数据库已备份至: $BACKUP_FILE"

# 备份到备份目录
cp app.db /opt/backups/app_pre_migration_$(date +%Y%m%d_%H%M%S).db
```

#### 3. 激活虚拟环境
```bash
cd /opt/point-rewards/point-rewards-backend
source venv/bin/activate
```

#### 4. 检查当前数据库状态
```bash
# 查看当前迁移版本
flask db current

# 查看迁移历史
flask db history

# 查看待执行的迁移
flask db show
```

## 创建迁移文件

### 1. 修改模型文件
首先在 `app/models.py` 中修改数据模型：

```python
# 示例：为 User 表添加新字段
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    # ... 现有字段 ...
    
    # 新增字段示例
    avatar_url = db.Column(db.String(255), nullable=True)  # 用户头像
    last_login = db.Column(db.DateTime, nullable=True)     # 最后登录时间
    is_verified = db.Column(db.Boolean, default=False)     # 是否验证
```

### 2. 生成迁移文件
```bash
# 自动生成迁移文件（推荐）
flask db migrate -m "添加用户头像和验证状态字段"

# 手动创建空迁移文件
flask db revision -m "手动迁移描述"
```

### 3. 检查生成的迁移文件
迁移文件位置：`migrations/versions/xxxxx_添加用户头像和验证状态字段.py`

```python
"""添加用户头像和验证状态字段

Revision ID: abc123def456
Revises: 2175629dc2dd
Create Date: 2024-01-01 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = 'abc123def456'
down_revision = '2175629dc2dd'
branch_labels = None
depends_on = None

def upgrade():
    # 升级操作
    with op.batch_alter_table('user', schema=None) as batch_op:
        batch_op.add_column(sa.Column('avatar_url', sa.String(length=255), nullable=True))
        batch_op.add_column(sa.Column('last_login', sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column('is_verified', sa.Boolean(), nullable=True))

def downgrade():
    # 降级操作
    with op.batch_alter_table('user', schema=None) as batch_op:
        batch_op.drop_column('is_verified')
        batch_op.drop_column('last_login')
        batch_op.drop_column('avatar_url')
```

## 执行迁移

### 1. 测试环境验证
```bash
# 在测试数据库上验证
cp app.db app_test.db
export DATABASE_URL=sqlite:///app_test.db
flask db upgrade
# 检查结果无误后继续
```

### 2. 停止服务
```bash
# 停止后端服务
sudo supervisorctl stop point-rewards-backend

# 或重启服务（推荐）
sudo supervisorctl restart point-rewards-backend
```

### 3. 执行迁移
```bash
# 执行迁移
flask db upgrade

# 检查迁移结果
flask db current
sqlite3 app.db ".schema user"  # 检查表结构
```

### 4. 验证迁移结果
```bash
# 使用数据查看工具验证
python utils/view_data.py users

# 检查新字段是否存在
sqlite3 app.db "PRAGMA table_info(user);"
```

### 5. 重启服务
```bash
# 重启后端服务
sudo supervisorctl start point-rewards-backend

# 检查服务状态
sudo supervisorctl status point-rewards-backend

# 查看日志确认启动成功
sudo tail -f /var/log/point-rewards-backend.log
```

## 回滚操作

### 1. 回滚到指定版本
```bash
# 查看迁移历史
flask db history

# 回滚到上一个版本
flask db downgrade

# 回滚到指定版本
flask db downgrade 2175629dc2dd
```

### 2. 紧急回滚
```bash
# 停止服务
sudo supervisorctl stop point-rewards-backend

# 恢复数据库备份
cp app_backup_20240101_120000.db app.db

# 重启服务
sudo supervisorctl start point-rewards-backend
```

## 常见场景示例

### 1. 添加新字段
```python
# models.py 中添加
email = db.Column(db.String(120), unique=True, nullable=True)
```

```bash
flask db migrate -m "添加用户邮箱字段"
flask db upgrade
```

### 2. 修改字段属性
```python
# 将字段从可空改为非空
phone = db.Column(db.String(20), nullable=False, default='')
```

```bash
flask db migrate -m "手机号字段设为必填"
# 注意：需要先为现有记录设置默认值
flask db upgrade
```

### 3. 添加新表
```python
class Category(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=False)
    description = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
```

```bash
flask db migrate -m "添加分类表"
flask db upgrade
```

### 4. 添加索引
```python
# 在模型中添加索引
class User(db.Model):
    # ... 其他字段 ...
    email = db.Column(db.String(120), index=True)  # 单字段索引
    
    # 复合索引
    __table_args__ = (
        db.Index('idx_user_status_created', 'status', 'created_at'),
    )
```

### 5. 删除字段（谨慎操作）
```python
# 先注释掉模型中的字段
# deprecated_field = db.Column(db.String(100))  # 已废弃
```

```bash
flask db migrate -m "删除废弃字段"
flask db upgrade
```

## 故障处理

### 1. 迁移失败处理
```bash
# 查看错误详情
flask db show

# 标记迁移为已完成（谨慎使用）
flask db stamp head

# 强制恢复到指定版本
flask db stamp 2175629dc2dd
```

### 2. 数据库锁定问题
```bash
# 检查是否有进程在使用数据库
sudo lsof app.db

# 停止所有相关服务
sudo supervisorctl stop point-rewards-backend
sudo systemctl stop nginx

# 重新执行迁移
flask db upgrade

# 重启服务
sudo supervisorctl start point-rewards-backend
sudo systemctl start nginx
```

### 3. 迁移文件冲突
```bash
# 如果有多个开发者同时创建迁移文件
flask db merge -m "合并迁移冲突"
```

## 最佳实践

### 1. 迁移前检查清单
- [ ] 数据库已备份
- [ ] 在测试环境验证过
- [ ] 迁移文件经过代码审查
- [ ] 服务停止时间已安排
- [ ] 回滚方案已准备

### 2. 安全操作原则
```bash
# 总是先备份
cp app.db app_backup_$(date +%Y%m%d_%H%M%S).db

# 在测试环境验证
cp app.db app_test.db

# 分步执行，逐步验证
flask db migrate -m "描述性的迁移信息"
flask db upgrade

# 立即验证结果
python utils/view_data.py summary
```

### 3. 监控和日志
```bash
# 迁移过程中监控日志
tail -f /var/log/point-rewards-backend.log

# 记录迁移操作
echo "$(date): 执行数据库迁移 - 添加用户头像字段" >> /var/log/db-migration.log
```

## 紧急联系和恢复

### 快速恢复脚本
```bash
#!/bin/bash
# 紧急恢复脚本 emergency_restore.sh

echo "开始紧急数据库恢复..."

# 停止服务
sudo supervisorctl stop point-rewards-backend

# 恢复最新备份
LATEST_BACKUP=$(ls -t /opt/backups/app_*.db | head -1)
echo "恢复备份文件: $LATEST_BACKUP"
cp "$LATEST_BACKUP" /opt/point-rewards/point-rewards-backend/app.db

# 重启服务
sudo supervisorctl start point-rewards-backend

echo "紧急恢复完成"
```

### 健康检查
```bash
# 检查数据库完整性
sqlite3 app.db "PRAGMA integrity_check;"

# 检查表结构
sqlite3 app.db ".schema"

# 检查服务状态
curl -f http://localhost:5000/api/health || echo "服务异常"
```

---

**重要提醒**: 
- **优先使用 `manage.sh` 统一管理工具**进行数据库操作，它集成了备份、修复、验证等功能
- 任何数据库变更都有风险，请严格按照此指南操作
- `sudo bash manage.sh fix-db` 是最安全的数据库修复方式
- 遇到问题时，首先运行 `bash manage.sh troubleshoot` 进行诊断
- 在生产环境执行前，建议先备份: `sudo bash manage.sh backup`