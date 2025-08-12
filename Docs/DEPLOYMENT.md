# 积分兑换平台部署文档

## 📋 项目概览

本项目包含三个主要组件：
- **point-rewards-backend**: Flask API 后端服务
- **point-rewards-frontend**: React 移动端用户界面 (points.eternalmoon.com.cn)
- **point-rewards-admin-web**: React 管理后台界面 (dashboard.eternalmoon.com.cn)

## 🚀 快速部署（推荐）

### 一键部署命令
```bash
# 1. 上传项目到服务器
cd point-rewards-hub-main

# 2. 配置DNS解析
# points.eternalmoon.com.cn      A    YOUR_SERVER_IP
# dashboard.eternalmoon.com.cn   A    YOUR_SERVER_IP

# 3. 一键部署（自动处理所有配置）
sudo bash manage.sh deploy

# 4. 创建管理员账户
sudo bash manage.sh create-admin
```

## 🔧 manage.sh 统一管理工具

### 基本使用
```bash
bash manage.sh help           # 查看所有命令
bash manage.sh status         # 查看服务状态
bash manage.sh test           # 测试网站访问
sudo bash manage.sh restart   # 重启服务
```

### 部署相关命令
```bash
sudo bash manage.sh deploy        # 标准部署
sudo bash manage.sh deploy-robust # 增强部署（生产环境推荐）
sudo bash manage.sh cleanup       # 完整清理
```

### 数据库管理命令
```bash
sudo bash manage.sh init-db       # 初始化数据库
sudo bash manage.sh fix-db        # 修复数据库问题（推荐）
sudo bash manage.sh create-admin  # 创建管理员账户
sudo bash manage.sh backup        # 备份数据库
sudo bash manage.sh view-data     # 查看数据库数据
```

### 诊断命令
```bash
bash manage.sh logs            # 查看服务日志
bash manage.sh troubleshoot    # 运行故障排查
bash manage.sh info            # 显示部署信息
```

## 🌐 域名配置

### DNS 记录配置
在域名管理面板中配置以下 A 记录：
```
points.eternalmoon.com.cn     A    YOUR_SERVER_IP
dashboard.eternalmoon.com.cn  A    YOUR_SERVER_IP
```

### 访问地址
- **移动端**: https://points.eternalmoon.com.cn
- **管理后台**: https://dashboard.eternalmoon.com.cn

## 🖥️ 服务器环境要求

### 系统要求
- **操作系统**: Ubuntu 20.04 LTS 或 CentOS 8+
- **内存**: 最低 2GB，推荐 4GB+
- **磁盘**: 最低 20GB 可用空间
- **网络**: 公网 IP 地址，用于 HTTPS 访问

### 软件要求
- **Python**: 3.8+ (manage.sh 会自动检测 python3/python)
- **Node.js**: 18.0+
- **npm**: 9.0+
- **Nginx**: 1.18+
- **Supervisor**: 4.0+ (可选，manage.sh 支持直接启动)

## 📖 详细部署步骤

### 1. 服务器准备
```bash
# 更新系统包
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
sudo yum update -y                       # CentOS/RHEL

# 安装基础软件
sudo apt install -y python3 python3-pip python3-venv nodejs npm nginx supervisor git
```

### 2. 上传项目文件
```bash
# 创建项目目录
sudo mkdir -p /opt/point-rewards
sudo chown $USER:$USER /opt/point-rewards
cd /opt/point-rewards

# 上传文件（方式1：git clone）
git clone <your-repository-url> .

# 或上传文件（方式2：scp）
# scp -r point-rewards-hub-main/ user@server:/opt/point-rewards/
```

### 3. 执行部署
```bash
cd /opt/point-rewards
sudo bash manage.sh deploy
```

部署脚本会自动：
- ✅ 检查并安装依赖
- ✅ 创建 Python 虚拟环境
- ✅ 构建前端项目
- ✅ 配置 Nginx
- ✅ 设置 Supervisor
- ✅ 获取 SSL 证书
- ✅ 初始化数据库

### 4. 创建管理员账户
```bash
sudo bash manage.sh create-admin
```

默认管理员信息：
- **账号**: admin
- **密码**: Eternalmoon.com1

### 5. 验证部署
```bash
# 查看服务状态
bash manage.sh status

# 测试网站访问
bash manage.sh test

# 查看部署信息
bash manage.sh info
```

## 🛠️ 高级配置

### 增强部署（生产环境推荐）
```bash
# 支持断点续传和错误恢复
sudo bash manage.sh deploy-robust
```

### 手动配置环境变量
如需自定义配置，编辑 `/opt/point-rewards/point-rewards-backend/.env`：
```env
SECRET_KEY=your-very-secure-secret-key-here
JWT_SECRET_KEY=your-jwt-secret-key-here
DATABASE_URL=sqlite:///app.db
FLASK_ENV=production
```

### Nginx 配置文件
位置：`/etc/nginx/sites-available/point-rewards`

如需修改配置后重启：
```bash
sudo nginx -t                # 测试配置
sudo systemctl reload nginx  # 重载配置
```

### Supervisor 配置文件
位置：`/etc/supervisor/conf.d/point-rewards-backend.conf`

管理命令：
```bash
sudo supervisorctl status                           # 查看状态
sudo supervisorctl restart point-rewards-backend   # 重启后端
# 或使用 manage.sh
sudo bash manage.sh restart
```

## 🔍 监控和维护

### 日常检查
```bash
# 查看服务状态（推荐每日检查）
bash manage.sh status

# 查看错误日志
bash manage.sh logs

# 测试网站访问
bash manage.sh test
```

### 数据备份
```bash
# 手动备份
sudo bash manage.sh backup

# 设置自动备份（可选）
echo "0 2 * * * /opt/point-rewards/manage.sh backup" | sudo crontab -
```

### 数据库维护
```bash
# 查看数据库数据
bash manage.sh view-data summary    # 数据汇总
bash manage.sh view-data users      # 用户表
bash manage.sh view-data prizes     # 奖品表

# 修复数据库问题
sudo bash manage.sh fix-db
```

## 🆘 故障排查

### 标准排查流程
```bash
# 1. 运行完整诊断
bash manage.sh troubleshoot

# 2. 查看详细状态
bash manage.sh status

# 3. 测试网络连通性
bash manage.sh test

# 4. 查看错误日志
bash manage.sh logs
```

### 常见问题解决

#### 1. 网站无法访问
```bash
bash manage.sh status    # 检查服务状态
bash manage.sh test      # 测试访问
sudo bash manage.sh restart  # 重启服务
```

#### 2. 数据库问题
```bash
sudo bash manage.sh fix-db  # 一键修复数据库和管理员账户
```

#### 3. 服务启动失败
```bash
bash manage.sh logs           # 查看错误日志
sudo bash manage.sh restart   # 重启服务
```

#### 4. SSL 证书问题
```bash
sudo certbot certificates     # 检查证书状态
sudo certbot renew           # 手动续期
```

### 完整重新部署
```bash
# 如果问题严重，可以完整重新部署
sudo bash manage.sh cleanup  # 清理所有配置
sudo bash manage.sh deploy   # 重新部署
```

## 📊 服务架构

### 服务组件
- **Frontend (移动端)**: `/var/www/points.eternalmoon.com.cn`
- **Admin (管理后台)**: `/var/www/dashboard.eternalmoon.com.cn`
- **Backend (API)**: `http://localhost:5000` (通过Nginx代理)
- **Database**: SQLite (`/opt/point-rewards/point-rewards-backend/app.db`)

### 进程管理
- **Nginx**: `systemctl status nginx`
- **Backend**: `supervisorctl status point-rewards-backend`
- **或使用**: `bash manage.sh status` 查看所有服务

### 日志位置
- **Backend**: `/var/log/point-rewards-backend-error.log`
- **Nginx**: `/var/log/nginx/error.log`
- **访问日志**: `/var/log/nginx/access.log`

## 🔐 安全配置

### 防火墙设置
```bash
# Ubuntu (ufw)
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw enable

# CentOS (firewalld)
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### SSL 证书自动续期
```bash
# 检查续期配置
sudo crontab -l | grep certbot

# 手动续期测试
sudo certbot renew --dry-run
```

## 🚀 更新部署

### 更新代码
```bash
# 1. 备份当前版本
sudo cp -r /opt/point-rewards /opt/point-rewards-backup-$(date +%Y%m%d)

# 2. 更新代码
cd /opt/point-rewards
git pull origin main  # 或重新上传文件

# 3. 重新部署
sudo bash manage.sh deploy

# 4. 重启服务
sudo bash manage.sh restart
```

## 💡 最佳实践

1. **使用 manage.sh 进行所有操作**
   ```bash
   # 推荐
   sudo bash manage.sh deploy
   
   # 避免直接使用底层命令
   ```

2. **定期监控**
   ```bash
   # 建议每日执行
   bash manage.sh status
   bash manage.sh test
   ```

3. **备份策略**
   ```bash
   # 重要操作前备份
   sudo bash manage.sh backup
   ```

4. **日志监控**
   ```bash
   # 定期查看日志
   bash manage.sh logs
   ```

## 📞 技术支持

如果在部署过程中遇到问题：

1. **首先运行诊断**: `bash manage.sh troubleshoot`
2. **查看完整日志**: `bash manage.sh logs`
3. **检查服务状态**: `bash manage.sh status`
4. **尝试重启服务**: `sudo bash manage.sh restart`

---

**注意**: 本文档适用于使用 `manage.sh` 的最新版本部署流程。所有命令都经过测试，确保在生产环境中的可靠性。