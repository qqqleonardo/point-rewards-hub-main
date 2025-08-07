# 积分兑换平台部署文档

## 项目概览

本项目包含三个主要组件：
- **point-rewards-backend**: Flask API 后端服务
- **point-rewards-frontend**: React 移动端用户界面 (points.eternalmoon.com.cn)
- **point-rewards-admin-web**: React 管理后台界面 (dashboard.eternalmoon.com.cn)

## 域名配置

本部署使用以下域名结构：
- **主域名**: eternalmoon.com.cn
- **移动端**: points.eternalmoon.com.cn
- **管理后台**: dashboard.eternalmoon.com.cn
- **API 服务**: 通过各自域名的 /api 路径访问

## 服务器环境要求

### 系统要求
- **操作系统**: Ubuntu 20.04 LTS 或 CentOS 8+
- **内存**: 最低 2GB，推荐 4GB+
- **磁盘**: 最低 20GB 可用空间
- **网络**: 公网 IP 地址，用于 HTTPS 访问

### 软件要求
- **Python**: 3.8+
- **Node.js**: 18.0+
- **npm**: 9.0+
- **Nginx**: 1.18+
- **Supervisor**: 4.0+ (进程管理)
- **SSL证书**: Let's Encrypt 或其他 CA 颁发的证书

## DNS 配置要求

在域名管理面板中配置以下 A 记录：
```
points.eternalmoon.com.cn     A    YOUR_SERVER_IP
dashboard.eternalmoon.com.cn  A    YOUR_SERVER_IP
```

可选的额外记录：
```
eternalmoon.com.cn           A    YOUR_SERVER_IP
www.eternalmoon.com.cn       A    YOUR_SERVER_IP
```

## 部署前准备

### 1. 更新系统包
```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

### 2. 安装基础软件
```bash
# Ubuntu/Debian
sudo apt install -y python3 python3-pip python3-venv nodejs npm nginx supervisor git

# CentOS/RHEL
sudo yum install -y python3 python3-pip nodejs npm nginx supervisor git
sudo yum install -y python3-virtualenv  # 如果没有 venv 模块
```

### 3. 创建项目目录
```bash
sudo mkdir -p /opt/point-rewards
sudo chown $USER:$USER /opt/point-rewards
cd /opt/point-rewards
```

### 4. 上传项目文件
```bash
# 方式1: 使用 git clone
git clone <your-repository-url> .

# 方式2: 使用 scp 上传
# 在本地执行：
# scp -r point-rewards-hub-main/ user@server:/opt/point-rewards/
```

## 后端部署 (Flask API)

### 1. 创建 Python 虚拟环境
```bash
cd /opt/point-rewards/point-rewards-backend
python3 -m venv venv
source venv/bin/activate
```

### 2. 安装 Python 依赖
```bash
pip install -r requirements.txt
```

### 3. 配置环境变量
```bash
# 创建环境配置文件
nano .env
```

在 `.env` 文件中添加：
```env
# 生产环境配置
SECRET_KEY=your-very-secure-secret-key-here
JWT_SECRET_KEY=your-jwt-secret-key-here
DATABASE_URL=sqlite:///app.db
FLASK_ENV=production
```

### 4. 初始化数据库
```bash
# 如果需要迁移数据库
flask db upgrade

# 创建管理员账户
python create_admin.py
```

### 5. 测试后端服务
```bash
python run.py
# 检查是否在 5000 端口正常运行
```

### 6. 配置 Supervisor 管理后端服务
创建 supervisor 配置文件：
```bash
sudo nano /etc/supervisor/conf.d/point-rewards-backend.conf
```

添加以下内容：
```ini
[program:point-rewards-backend]
command=/opt/point-rewards/point-rewards-backend/venv/bin/python run.py
directory=/opt/point-rewards/point-rewards-backend
user=www-data
autostart=true
autorestart=true
stdout_logfile=/var/log/point-rewards-backend.log
stderr_logfile=/var/log/point-rewards-backend-error.log
environment=PYTHONPATH=/opt/point-rewards/point-rewards-backend
```

启动后端服务：
```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start point-rewards-backend
```

## 前端部署 (React 应用)

### 1. 构建移动端前端
```bash
cd /opt/point-rewards/point-rewards-frontend

# 安装依赖
npm install

# 配置生产环境 API 地址
# 编辑 src/lib/api.ts 或相关配置文件，确保 API_BASE_URL 指向生产服务器
nano src/lib/api.ts

# 构建生产版本
npm run build
```

### 2. 构建管理后台
```bash
cd /opt/point-rewards/point-rewards-admin-web

# 安装依赖
npm install

# 构建生产版本
npm run build
```

### 3. 复制构建文件到 Web 目录
```bash
# 创建 web 目录
sudo mkdir -p /var/www/points.eternalmoon.com.cn
sudo mkdir -p /var/www/dashboard.eternalmoon.com.cn

# 复制移动端构建文件
sudo cp -r /opt/point-rewards/point-rewards-frontend/dist/* /var/www/points.eternalmoon.com.cn/

# 复制管理后台构建文件
sudo cp -r /opt/point-rewards/point-rewards-admin-web/dist/* /var/www/dashboard.eternalmoon.com.cn/

# 设置权限
sudo chown -R www-data:www-data /var/www/points.eternalmoon.com.cn
sudo chown -R www-data:www-data /var/www/dashboard.eternalmoon.com.cn
sudo chmod -R 755 /var/www/points.eternalmoon.com.cn
sudo chmod -R 755 /var/www/dashboard.eternalmoon.com.cn
```

## Nginx 配置

### 1. 获取 SSL 证书
使用 Let's Encrypt 获取免费 SSL 证书：
```bash
# 安装 certbot
sudo apt install certbot python3-certbot-nginx  # Ubuntu/Debian
sudo yum install certbot python3-certbot-nginx  # CentOS/RHEL

# 获取证书 (为两个二级域名)
sudo certbot certonly --nginx -d points.eternalmoon.com.cn -d dashboard.eternalmoon.com.cn
```

### 2. 配置 Nginx
创建 Nginx 配置文件：
```bash
sudo nano /etc/nginx/sites-available/point-rewards
```

添加以下配置：
```nginx
# HTTP 重定向到 HTTPS
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS 主配置
server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    # SSL 证书配置
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # 文件上传大小限制
    client_max_body_size 50M;

    # 移动端前端 (默认路由)
    location / {
        root /var/www/point-rewards;
        try_files $uri $uri/ /index.html;
        
        # 缓存静态资源
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # 管理后台
    location /admin {
        alias /var/www/point-rewards/admin;
        try_files $uri $uri/ /admin/index.html;
    }

    # API 代理到后端
    location /api {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # 静态文件上传目录
    location /static {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 3. 启用配置并重启 Nginx
```bash
# 启用站点配置
sudo ln -s /etc/nginx/sites-available/point-rewards /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx
```

## 系统服务配置

### 1. 设置服务自启动
```bash
# 启用 Nginx 自启动
sudo systemctl enable nginx

# 启用 Supervisor 自启动
sudo systemctl enable supervisor
```

### 2. 配置防火墙
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

### 3. 配置日志轮转
创建日志轮转配置：
```bash
sudo nano /etc/logrotate.d/point-rewards
```

添加内容：
```
/var/log/point-rewards-*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    copytruncate
}
```

## 部署后验证

### 1. 检查服务状态
```bash
# 检查后端服务
sudo supervisorctl status point-rewards-backend

# 检查 Nginx
sudo systemctl status nginx

# 检查端口监听
sudo netstat -tlnp | grep -E ':80|:443|:5000'
```

### 2. 测试访问
```bash
# 测试 API 健康检查
curl -k https://yourdomain.com/api/health

# 测试前端访问
curl -k https://yourdomain.com

# 测试管理后台
curl -k https://yourdomain.com/admin
```

### 3. 检查日志
```bash
# 查看后端日志
sudo tail -f /var/log/point-rewards-backend.log

# 查看 Nginx 日志
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## 维护和监控

### 1. 备份数据库
```bash
# 创建备份脚本
sudo nano /opt/backup-db.sh
```

添加内容：
```bash
#!/bin/bash
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# 备份 SQLite 数据库
cp /opt/point-rewards/point-rewards-backend/app.db $BACKUP_DIR/app_$DATE.db

# 保留最近 30 天的备份
find $BACKUP_DIR -name "app_*.db" -mtime +30 -delete
```

设置定时备份：
```bash
sudo chmod +x /opt/backup-db.sh
echo "0 2 * * * /opt/backup-db.sh" | sudo crontab -
```

### 2. 监控服务
可以使用以下命令监控服务状态：
```bash
# 监控脚本
#!/bin/bash
echo "=== 服务状态 ==="
sudo supervisorctl status
echo "=== Nginx 状态 ==="
sudo systemctl status nginx --no-pager
echo "=== 磁盘使用 ==="
df -h
echo "=== 内存使用 ==="
free -h
```

## 故障排除

### 常见问题和解决方案

1. **后端服务无法启动**
   - 检查虚拟环境和依赖安装
   - 查看 supervisor 日志：`sudo tail -f /var/log/point-rewards-backend-error.log`

2. **前端页面无法加载**
   - 检查 Nginx 配置和文件权限
   - 确认构建文件是否正确复制

3. **SSL 证书问题**
   - 检查证书路径：`sudo certbot certificates`
   - 续期证书：`sudo certbot renew`

4. **数据库连接问题**
   - 检查数据库文件权限
   - 确认数据库路径配置

5. **API 请求失败**
   - 检查后端服务状态
   - 查看 Nginx 代理配置

## 更新部署

### 更新代码
```bash
# 1. 备份当前版本
sudo cp -r /opt/point-rewards /opt/point-rewards-backup-$(date +%Y%m%d)

# 2. 更新代码
cd /opt/point-rewards
git pull origin main  # 或者重新上传文件

# 3. 更新后端
cd point-rewards-backend
source venv/bin/activate
pip install -r requirements.txt
sudo supervisorctl restart point-rewards-backend

# 4. 重新构建前端
cd ../point-rewards-frontend
npm install
npm run build
sudo cp -r dist/* /var/www/point-rewards/

cd ../point-rewards-admin-web
npm install
npm run build
sudo cp -r dist/* /var/www/point-rewards/admin/

# 5. 重启服务
sudo systemctl reload nginx
```

## 安全建议

1. **定期更新系统和软件包**
2. **使用强密码和 SSH 密钥认证**
3. **配置防火墙，只开放必要端口**
4. **定期备份数据**
5. **监控系统日志和异常访问**
6. **定期更新 SSL 证书**

## 联系信息

如果在部署过程中遇到问题，请检查：
1. 系统日志：`/var/log/`
2. 应用日志：`/var/log/point-rewards-*.log`
3. Nginx 日志：`/var/log/nginx/`

---

**注意**: 请将配置文件中的 `yourdomain.com` 替换为你的实际域名，并根据实际情况调整路径和配置参数。