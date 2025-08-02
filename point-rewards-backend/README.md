# 项目初始化和启动指南

本项目是一个基于 Flask 的积分兑换后端应用。请按照以下步骤进行初始化和启动。

## 1. 环境准备

建议使用 Python 虚拟环境来管理项目依赖，避免与系统全局环境冲突。

```bash
# 创建虚拟环境 (如果 venv 目录不存在)
python -m venv venv

# 激活虚拟环境
.\venv\Scripts\activate
```

## 2. 安装依赖

激活虚拟环境后，使用 `pip` 安装 `requirements.txt` 文件中列出的所有依赖库。

```bash
pip install -r requirements.txt
```

## 3. 初始化数据库

项目使用 Flask-Migrate 管理数据库。执行以下命令来创建数据库文件 (`app.db`) 和表结构。

**重要提示**: 在 Windows 命令提示符 (cmd) 中，请使用 `set` 命令。如果您使用 PowerShell，请使用 `$env:FLASK_APP="run.py"`。

```bash
# 设置 Flask 应用入口 (必须)
set FLASK_APP=run.py

# 初始化数据库迁移环境 (仅在第一次设置时需要)
flask db init

# 生成迁移脚本
flask db migrate -m "Initial migration."

# 应用迁移，创建数据库表
flask db upgrade
```

执行完毕后，项目根目录下会生成一个 `app.db` 文件，这就是应用的 SQLite 数据库。

## 4. 创建管理员账户

项目提供了一个脚本用于创建默认的管理员账户。

```bash
python create_admin.py
```

成功后会显示管理员的登录信息：
- **手机号:** `admin`
- **密码:** `admin123`

## 5. 启动项目

完成以上所有步骤后，运行以下命令即可启动 Flask Web 服务器。

```bash
python run.py
```

服务将默认在 `http://0.0.0.0:5000` 上运行。您现在可以通过 API 工具 (如 Postman) 或前端应用访问后端接口了。
