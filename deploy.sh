#!/bin/bash

# 积分兑换平台快速部署脚本 - eternalmoon.com.cn
# 使用方法: sudo bash deploy.sh

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 域名配置
MOBILE_DOMAIN="points.eternalmoon.com.cn"
ADMIN_DOMAIN="dashboard.eternalmoon.com.cn"
BASE_DOMAIN="eternalmoon.com.cn"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否以 root 权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限运行，请使用 sudo"
        exit 1
    fi
}

# 检测系统类型
detect_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        log_error "无法检测系统类型"
        exit 1
    fi
    log_info "检测到系统: $OS $VER"
}

# 更新系统
update_system() {
    log_info "更新系统包..."
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        apt update && apt upgrade -y
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        yum update -y
    else
        log_warning "未知系统类型，跳过系统更新"
    fi
    log_success "系统更新完成"
}

# 安装基础软件
install_packages() {
    log_info "安装基础软件包..."
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        apt install -y python3 python3-pip python3-venv nodejs npm nginx supervisor git curl
        # 安装 certbot
        apt install -y certbot python3-certbot-nginx
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        yum install -y python3 python3-pip nodejs npm nginx supervisor git curl
        yum install -y python3-virtualenv
        # 安装 EPEL 和 certbot
        yum install -y epel-release
        yum install -y certbot python3-certbot-nginx
    else
        log_error "不支持的系统类型"
        exit 1
    fi
    log_success "基础软件包安装完成"
}

# 创建项目目录
create_directories() {
    log_info "创建项目目录..."
    mkdir -p /opt/point-rewards
    mkdir -p /var/www/$MOBILE_DOMAIN
    mkdir -p /var/www/$ADMIN_DOMAIN
    mkdir -p /opt/backups
    mkdir -p /var/log
    log_success "项目目录创建完成"
}

# 部署后端
deploy_backend() {
    log_info "部署后端服务..."
    cd /opt/point-rewards/point-rewards-backend
    
    # 检查和创建虚拟环境
    if [ -d "venv" ]; then
        log_info "虚拟环境已存在，检查完整性..."
        if [ ! -f "venv/bin/python" ]; then
            log_warning "虚拟环境损坏，重新创建..."
            rm -rf venv
            python3 -m venv venv
        fi
    else
        log_info "创建Python虚拟环境..."
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    
    # 升级pip并安装依赖
    log_info "安装Python依赖..."
    pip install --upgrade pip
    
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
    else
        log_warning "requirements.txt不存在，安装基础依赖..."
        pip install flask flask-sqlalchemy flask-migrate flask-cors python-dotenv werkzeug
    fi
    
    # 创建环境变量文件
    if [ ! -f ".env" ]; then
        log_info "创建环境变量配置..."
        cat > .env << EOF
SECRET_KEY=$(openssl rand -hex 32)
JWT_SECRET_KEY=$(openssl rand -hex 32)
DATABASE_URL=sqlite:///app.db
FLASK_ENV=production
FLASK_APP=run.py
EOF
    else
        log_success "环境变量文件已存在"
    fi
    
    # 检查主应用文件，如果不存在则创建基础版本
    main_files=("run.py" "app.py" "main.py")
    main_file=""
    
    for file in "${main_files[@]}"; do
        if [ -f "$file" ]; then
            main_file="$file"
            log_success "找到主应用文件: $file"
            break
        fi
    done
    
    if [ -z "$main_file" ]; then
        log_warning "未找到主应用文件，创建基础run.py..."
        cat > run.py << 'EOF'
from flask import Flask, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
import os
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

app = Flask(__name__)
CORS(app)

# 配置数据库
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', 'sqlite:///app.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# 基础模型
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128))
    points = db.Column(db.Integer, default=0)
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())

class Admin(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128))
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())

# API路由
@app.route('/')
def home():
    return jsonify({'message': 'Point Rewards API is running', 'status': 'success'})

@app.route('/api/health')
def health():
    return jsonify({'status': 'healthy', 'message': 'API is working'})

# 创建数据库表
with app.app_context():
    db.create_all()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF
        main_file="run.py"
        log_success "基础应用文件创建完成"
    fi
    
    # 创建管理员创建脚本
    create_admin_script
    
    deactivate
    log_success "后端部署完成"
}

# 创建管理员创建脚本函数
create_admin_script() {
    log_info "创建管理员账户脚本..."
    
    # 检查是否已有管理员脚本
    admin_scripts=("utils/create_admin.py" "create_admin.py")
    admin_script=""
    
    for script in "${admin_scripts[@]}"; do
        if [ -f "$script" ]; then
            admin_script="$script"
            log_success "管理员脚本已存在: $script"
            return
        fi
    done
    
    # 创建管理员脚本
    log_info "生成管理员创建脚本..."
    cat > create_admin.py << 'EOF'
#!/usr/bin/env python3
import os
import sys
from werkzeug.security import generate_password_hash
import getpass

# 添加项目根目录到Python路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from run import app, db, Admin
except ImportError:
    try:
        from app import app, db, Admin
    except ImportError:
        try:
            from main import app, db, Admin
        except ImportError:
            print("错误: 无法导入应用和数据库模块")
            sys.exit(1)

def create_admin():
    with app.app_context():
        print("=== 创建管理员账户 ===")
        
        # 检查是否已有管理员
        try:
            existing_admin = Admin.query.first()
            if existing_admin:
                print(f"已存在管理员账户: {existing_admin.username}")
                choice = input("是否要创建新的管理员? (y/N): ").lower()
                if choice != 'y':
                    print("取消创建")
                    return
        except Exception:
            # 表可能不存在，继续创建
            pass
        
        # 获取管理员信息
        username = input("输入管理员用户名 (默认: admin): ").strip() or "admin"
        email = input("输入管理员邮箱 (默认: admin@example.com): ").strip() or "admin@example.com"
        
        # 检查用户名是否已存在
        try:
            existing = Admin.query.filter_by(username=username).first()
            if existing:
                print(f"错误: 用户名 '{username}' 已存在")
                return
        except Exception:
            pass
        
        # 获取密码
        while True:
            password = getpass.getpass("输入管理员密码: ")
            if len(password) < 6:
                print("密码长度至少6位，请重新输入")
                continue
            
            confirm_password = getpass.getpass("确认密码: ")
            if password != confirm_password:
                print("密码不匹配，请重新输入")
                continue
            break
        
        # 创建管理员
        try:
            password_hash = generate_password_hash(password)
            admin = Admin(
                username=username,
                email=email,
                password_hash=password_hash
            )
            
            db.session.add(admin)
            db.session.commit()
            
            print(f"✅ 管理员账户创建成功!")
            print(f"用户名: {username}")
            print(f"邮箱: {email}")
            
        except Exception as e:
            db.session.rollback()
            print(f"❌ 创建管理员失败: {e}")

if __name__ == "__main__":
    create_admin()
EOF
    
    chmod +x create_admin.py
    log_success "管理员创建脚本已生成"
}

# 配置 Supervisor
configure_supervisor() {
    log_info "配置 Supervisor..."
    
    # 检查主应用文件
    cd /opt/point-rewards/point-rewards-backend
    main_files=("run.py" "app.py" "main.py")
    main_file="run.py"  # 默认使用run.py
    
    for file in "${main_files[@]}"; do
        if [ -f "$file" ]; then
            main_file="$file"
            break
        fi
    done
    
    log_info "使用主应用文件: $main_file"
    
    # 创建优化的Supervisor配置
    cat > /etc/supervisor/conf.d/point-rewards-backend.conf << EOF
[program:point-rewards-backend]
command=/opt/point-rewards/point-rewards-backend/venv/bin/python $main_file
directory=/opt/point-rewards/point-rewards-backend
user=www-data
autostart=true
autorestart=true
stdout_logfile=/var/log/point-rewards-backend.log
stderr_logfile=/var/log/point-rewards-backend-error.log
stdout_logfile_maxbytes=50MB
stderr_logfile_maxbytes=50MB
stdout_logfile_backups=10
stderr_logfile_backups=10
environment=PYTHONPATH="/opt/point-rewards/point-rewards-backend",FLASK_ENV="production"
redirect_stderr=false
startsecs=10
startretries=5
stopsignal=TERM
stopwaitsecs=30
killasgroup=true
stopasgroup=true
EOF
    
    # 设置正确的权限
    chown -R www-data:www-data /opt/point-rewards/point-rewards-backend
    chmod +x /opt/point-rewards/point-rewards-backend/venv/bin/python
    
    # 重新加载Supervisor配置
    supervisorctl reread
    supervisorctl update
    
    # 确保服务停止后重新启动
    supervisorctl stop point-rewards-backend 2>/dev/null || true
    sleep 2
    supervisorctl start point-rewards-backend
    
    log_success "Supervisor 配置完成"
}

# 部署前端
deploy_frontend() {
    log_info "部署移动端前端..."
    cd /opt/point-rewards/point-rewards-frontend
    
    # 检查 Node.js 版本
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 16 ]; then
        log_warning "Node.js 版本过低，建议升级到 16+ 版本"
    fi
    
    npm install
    npm run build
    
    # 复制构建文件
    cp -r dist/* /var/www/$MOBILE_DOMAIN/
    
    log_info "部署管理后台..."
    cd /opt/point-rewards/point-rewards-admin-web
    npm install
    npm run build
    
    # 复制管理后台文件
    cp -r dist/* /var/www/$ADMIN_DOMAIN/
    
    # 设置权限
    chown -R www-data:www-data /var/www/$MOBILE_DOMAIN
    chown -R www-data:www-data /var/www/$ADMIN_DOMAIN
    chmod -R 755 /var/www/$MOBILE_DOMAIN
    chmod -R 755 /var/www/$ADMIN_DOMAIN
    
    log_success "前端部署完成"
}

# 获取 SSL 证书
setup_ssl() {
    log_info "设置 SSL 证书..."
    
    # 先启动 nginx 基础配置
    setup_nginx_basic
    
    # 获取 Let's Encrypt 证书
    certbot --nginx -d $MOBILE_DOMAIN -d $ADMIN_DOMAIN --non-interactive --agree-tos --email admin@$BASE_DOMAIN --redirect
    
    if [ $? -eq 0 ]; then
        log_success "SSL 证书获取成功"
    else
        log_warning "SSL 证书获取失败，将使用自签名证书"
        setup_self_signed_ssl
    fi
}

# 创建自签名 SSL 证书（用于测试）
setup_self_signed_ssl() {
    log_info "创建自签名 SSL 证书..."
    mkdir -p /etc/ssl/private
    
    # 为移动端域名创建证书
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/$MOBILE_DOMAIN.key \
        -out /etc/ssl/certs/$MOBILE_DOMAIN.crt \
        -subj "/C=CN/ST=State/L=City/O=Organization/CN=$MOBILE_DOMAIN"
    
    # 为管理后台域名创建证书
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/$ADMIN_DOMAIN.key \
        -out /etc/ssl/certs/$ADMIN_DOMAIN.crt \
        -subj "/C=CN/ST=State/L=City/O=Organization/CN=$ADMIN_DOMAIN"
    
    log_success "自签名证书创建完成"
}

# 配置 Nginx 基础版本
setup_nginx_basic() {
    log_info "配置 Nginx 基础版本..."
    cat > /etc/nginx/sites-available/point-rewards << EOF
# 移动端 - $MOBILE_DOMAIN
server {
    listen 80;
    server_name $MOBILE_DOMAIN;
    
    location / {
        root /var/www/$MOBILE_DOMAIN;
        try_files \$uri \$uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /static {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}

# 管理后台 - $ADMIN_DOMAIN
server {
    listen 80;
    server_name $ADMIN_DOMAIN;
    
    location / {
        root /var/www/$ADMIN_DOMAIN;
        try_files \$uri \$uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /static {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
    
    # 启用配置
    ln -sf /etc/nginx/sites-available/point-rewards /etc/nginx/sites-enabled/
    
    # 删除默认配置
    rm -f /etc/nginx/sites-enabled/default
    
    # 测试配置
    nginx -t
    systemctl reload nginx
}

# 配置 Nginx HTTPS 版本
setup_nginx_https() {
    log_info "配置 Nginx HTTPS..."
    
    # 确定证书路径
    if [ -f "/etc/letsencrypt/live/$MOBILE_DOMAIN/fullchain.pem" ]; then
        MOBILE_CERT_PATH="/etc/letsencrypt/live/$MOBILE_DOMAIN/fullchain.pem"
        MOBILE_KEY_PATH="/etc/letsencrypt/live/$MOBILE_DOMAIN/privkey.pem"
        ADMIN_CERT_PATH="/etc/letsencrypt/live/$MOBILE_DOMAIN/fullchain.pem"
        ADMIN_KEY_PATH="/etc/letsencrypt/live/$MOBILE_DOMAIN/privkey.pem"
    else
        MOBILE_CERT_PATH="/etc/ssl/certs/$MOBILE_DOMAIN.crt"
        MOBILE_KEY_PATH="/etc/ssl/private/$MOBILE_DOMAIN.key"
        ADMIN_CERT_PATH="/etc/ssl/certs/$ADMIN_DOMAIN.crt"
        ADMIN_KEY_PATH="/etc/ssl/private/$ADMIN_DOMAIN.key"
    fi
    
    cat > /etc/nginx/sites-available/point-rewards << EOF
# 移动端 - $MOBILE_DOMAIN
server {
    listen 80;
    server_name $MOBILE_DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $MOBILE_DOMAIN;

    # SSL 证书配置
    ssl_certificate $MOBILE_CERT_PATH;
    ssl_certificate_key $MOBILE_KEY_PATH;
    
    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # 文件上传大小限制
    client_max_body_size 50M;

    # 移动端前端
    location / {
        root /var/www/$MOBILE_DOMAIN;
        try_files \$uri \$uri/ /index.html;
        
        # 缓存静态资源
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # API 代理到后端
    location /api {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # 静态文件上传目录
    location /static {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

# 管理后台 - $ADMIN_DOMAIN
server {
    listen 80;
    server_name $ADMIN_DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $ADMIN_DOMAIN;

    # SSL 证书配置
    ssl_certificate $ADMIN_CERT_PATH;
    ssl_certificate_key $ADMIN_KEY_PATH;
    
    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # 文件上传大小限制
    client_max_body_size 50M;

    # 管理后台前端
    location / {
        root /var/www/$ADMIN_DOMAIN;
        try_files \$uri \$uri/ /index.html;
        
        # 缓存静态资源
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # API 代理到后端
    location /api {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # 静态文件上传目录
    location /static {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # 重新加载配置
    nginx -t && systemctl reload nginx
    log_success "Nginx HTTPS 配置完成"
}

# 配置防火墙
setup_firewall() {
    log_info "配置防火墙..."
    
    if command -v ufw >/dev/null 2>&1; then
        # Ubuntu/Debian
        ufw --force reset
        ufw allow 22/tcp      # SSH
        ufw allow 80/tcp      # HTTP
        ufw allow 443/tcp     # HTTPS
        ufw --force enable
    elif command -v firewall-cmd >/dev/null 2>&1; then
        # CentOS/RHEL
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
    else
        log_warning "未检测到防火墙工具，请手动配置"
    fi
    
    log_success "防火墙配置完成"
}

# 启动服务
start_services() {
    log_info "启动所有服务..."
    
    # 启动后端服务
    supervisorctl start point-rewards-backend
    
    # 启动并启用 nginx
    systemctl enable nginx
    systemctl start nginx
    
    # 启用 supervisor
    systemctl enable supervisor
    systemctl start supervisor
    
    log_success "服务启动完成"
}

# 创建备份脚本
setup_backup() {
    log_info "设置备份脚本..."
    cat > /opt/backup-db.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# 备份 SQLite 数据库
if [ -f "/opt/point-rewards/point-rewards-backend/app.db" ]; then
    cp /opt/point-rewards/point-rewards-backend/app.db $BACKUP_DIR/app_$DATE.db
    echo "数据库备份完成: app_$DATE.db"
fi

# 保留最近 30 天的备份
find $BACKUP_DIR -name "app_*.db" -mtime +30 -delete
EOF
    
    chmod +x /opt/backup-db.sh
    
    # 创建 SSL 证书续期脚本
    cat > /opt/renew-ssl.sh << 'EOF'
#!/bin/bash
# SSL 证书自动续期脚本
LOG_FILE="/var/log/ssl-renewal.log"

echo "$(date): 开始检查 SSL 证书续期" >> $LOG_FILE

# 尝试续期证书
if certbot renew --quiet --no-self-upgrade >> $LOG_FILE 2>&1; then
    echo "$(date): SSL 证书续期检查完成" >> $LOG_FILE
    # 重载 nginx 配置
    systemctl reload nginx >> $LOG_FILE 2>&1
    echo "$(date): Nginx 配置已重载" >> $LOG_FILE
else
    echo "$(date): SSL 证书续期失败" >> $LOG_FILE
fi
EOF
    
    chmod +x /opt/renew-ssl.sh
    
    # 添加到 crontab（避免重复）
    current_cron=$(crontab -l 2>/dev/null || echo "")
    
    if ! echo "$current_cron" | grep -q "/opt/backup-db.sh"; then
        (echo "$current_cron"; echo "0 2 * * * /opt/backup-db.sh") | crontab -
    fi
    
    if ! echo "$current_cron" | grep -q "/opt/renew-ssl.sh"; then
        (crontab -l 2>/dev/null; echo "0 3 * * * /opt/renew-ssl.sh") | crontab -
    fi
    
    log_success "备份脚本设置完成"
}

# 验证部署
verify_deployment() {
    log_info "验证部署状态..."
    
    # 检查服务状态
    echo "=== 服务状态 ==="
    supervisorctl status point-rewards-backend
    systemctl status nginx --no-pager
    
    # 检查端口
    echo "=== 端口监听 ==="
    netstat -tlnp | grep -E ':80|:443|:5000' || ss -tlnp | grep -E ':80|:443|:5000'
    
    # 测试 HTTP 请求
    echo "=== HTTP 测试 ==="
    if command -v curl >/dev/null 2>&1; then
        echo "测试移动端访问:"
        curl -s -o /dev/null -w "%{http_code}" http://$MOBILE_DOMAIN/ || echo "HTTP 测试失败"
        
        echo "测试管理后台访问:"
        curl -s -o /dev/null -w "%{http_code}" http://$ADMIN_DOMAIN/ || echo "HTTP 测试失败"
        
        if [ -f "/etc/letsencrypt/live/$MOBILE_DOMAIN/fullchain.pem" ] || [ -f "/etc/ssl/certs/$MOBILE_DOMAIN.crt" ]; then
            echo "测试 HTTPS 访问:"
            curl -s -o /dev/null -w "%{http_code}" -k https://$MOBILE_DOMAIN/ || echo "HTTPS 测试失败"
            curl -s -o /dev/null -w "%{http_code}" -k https://$ADMIN_DOMAIN/ || echo "HTTPS 测试失败"
        fi
    fi
    
    log_success "部署验证完成"
}

# 显示部署信息
show_deployment_info() {
    echo ""
    echo "=========================================="
    log_success "eternalmoon.com.cn 积分兑换平台部署完成！"
    echo "=========================================="
    echo ""
    echo "访问地址:"
    echo "  移动端: https://$MOBILE_DOMAIN"
    echo "  管理后台: https://$ADMIN_DOMAIN"
    echo "  移动端 API: https://$MOBILE_DOMAIN/api"
    echo "  管理后台 API: https://$ADMIN_DOMAIN/api"
    echo ""
    echo "重要文件位置:"
    echo "  项目目录: /opt/point-rewards"
    echo "  移动端 Web 目录: /var/www/$MOBILE_DOMAIN"
    echo "  管理后台 Web 目录: /var/www/$ADMIN_DOMAIN"
    echo "  日志目录: /var/log"
    echo "  备份目录: /opt/backups"
    echo ""
    echo "管理命令:"
    echo "  查看后端日志: sudo tail -f /var/log/point-rewards-backend.log"
    echo "  重启后端: sudo supervisorctl restart point-rewards-backend"
    echo "  重启 Nginx: sudo systemctl restart nginx"
    echo "  手动备份: sudo /opt/backup-db.sh"
    echo "  SSL证书续期: sudo /opt/renew-ssl.sh"
    echo "  查看SSL续期日志: sudo tail -f /var/log/ssl-renewal.log"
    echo ""
    echo "下一步:"
    echo "1. 创建管理员账户:"
    echo "   sudo bash manage.sh create-admin"
    echo "   或手动运行:"
    echo "   cd /opt/point-rewards/point-rewards-backend"
    echo "   source venv/bin/activate"
    echo "   python create_admin.py"
    echo ""
    echo "2. 确保 DNS 记录已配置:"
    echo "   $MOBILE_DOMAIN     A    YOUR_SERVER_IP"
    echo "   $ADMIN_DOMAIN  A    YOUR_SERVER_IP"
    echo ""
    echo "3. 访问管理后台配置奖品和用户数据"
    echo ""
    if [ ! -f "/etc/letsencrypt/live/$MOBILE_DOMAIN/fullchain.pem" ]; then
        log_warning "注意: 当前使用自签名证书，浏览器会显示安全警告"
        echo "   如需正式 SSL 证书，请确保域名已解析到此服务器，然后运行:"
        echo "   sudo certbot --nginx -d $MOBILE_DOMAIN -d $ADMIN_DOMAIN"
    fi
    echo "=========================================="
}

# 主函数
main() {
    echo "=========================================="
    echo "   eternalmoon.com.cn 积分兑换平台自动部署"
    echo "=========================================="
    echo ""
    echo "将部署以下域名:"
    echo "  移动端: $MOBILE_DOMAIN"
    echo "  管理后台: $ADMIN_DOMAIN"
    echo ""
    
    check_root
    detect_system
    
    # 确认继续
    read -p "继续部署? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "部署已取消"
        exit 0
    fi
    
    # 检查项目文件是否存在
    if [ ! -d "point-rewards-backend" ] || [ ! -d "point-rewards-frontend" ] || [ ! -d "point-rewards-admin-web" ]; then
        log_error "请在项目根目录下运行此脚本"
        log_error "确保存在以下目录: point-rewards-backend, point-rewards-frontend, point-rewards-admin-web"
        exit 1
    fi
    
    # 复制项目文件
    log_info "复制项目文件到 /opt/point-rewards..."
    cp -r . /opt/point-rewards/
    
    # 执行部署步骤
    update_system
    install_packages
    create_directories
    deploy_backend
    configure_supervisor
    deploy_frontend
    setup_ssl
    setup_nginx_https
    setup_firewall
    start_services
    setup_backup
    
    # 初始化数据库
    log_info "初始化数据库..."
    init_database_after_deploy
    
    verify_deployment
    show_deployment_info
    
    log_success "部署脚本执行完成！"
}

# 数据库初始化函数
init_database_after_deploy() {
    log_info "初始化数据库..."
    cd /opt/point-rewards/point-rewards-backend
    
    # 激活虚拟环境
    source venv/bin/activate
    
    # 多重方式初始化数据库
    db_initialized=false
    
    # 方法1：尝试使用Flask应用初始化
    log_info "尝试通过Flask应用初始化数据库..."
    main_files=("run.py" "app.py" "main.py")
    
    for main_file in "${main_files[@]}"; do
        if [ -f "$main_file" ]; then
            python3 -c "
try:
    from $main_file import app, db
    with app.app_context():
        db.create_all()
        print('✅ 通过 $main_file 创建数据库成功')
        import os
        if os.path.exists('app.db'):
            print(f'数据库文件大小: {os.path.getsize(\"app.db\")} bytes')
except Exception as e:
    print(f'❌ 通过 $main_file 初始化失败: {e}')
    raise
" 2>/dev/null && { db_initialized=true; break; } || continue
        fi
    done
    
    # 方法2：如果Flask方式失败，手动创建数据库
    if [ "$db_initialized" = false ]; then
        log_warning "Flask方式失败，使用手动方式创建数据库..."
        python3 -c "
import sqlite3
import os

db_path = 'app.db'
print(f'手动创建数据库: {db_path}')

try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # 创建用户表
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username VARCHAR(80) UNIQUE NOT NULL,
        email VARCHAR(120) UNIQUE NOT NULL,
        password_hash VARCHAR(128),
        points INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )''')
    
    # 创建管理员表
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS admins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username VARCHAR(80) UNIQUE NOT NULL,
        email VARCHAR(120) UNIQUE NOT NULL,
        password_hash VARCHAR(128),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )''')
    
    # 创建奖品表
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS prizes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(120) NOT NULL,
        description TEXT,
        points_required INTEGER NOT NULL,
        stock INTEGER DEFAULT 0,
        image_url VARCHAR(255),
        is_active BOOLEAN DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )''')
    
    # 创建兑换记录表
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS redemptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        prize_id INTEGER NOT NULL,
        points_spent INTEGER NOT NULL,
        status VARCHAR(20) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (prize_id) REFERENCES prizes (id)
    )''')
    
    # 创建积分交易记录表
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS point_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        points INTEGER NOT NULL,
        transaction_type VARCHAR(20) NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
    )''')
    
    conn.commit()
    
    # 验证表创建
    cursor.execute(\"SELECT name FROM sqlite_master WHERE type='table'\")
    tables = cursor.fetchall()
    print(f'✅ 创建了 {len(tables)} 个数据表: {[table[0] for table in tables]}')
    
    conn.close()
    
    # 检查文件大小
    if os.path.exists(db_path):
        size = os.path.getsize(db_path)
        print(f'数据库文件大小: {size} bytes')
        if size > 0:
            print('✅ 数据库创建成功')
        else:
            print('❌ 数据库文件为空')
    else:
        print('❌ 数据库文件不存在')
        
except Exception as e:
    print(f'❌ 手动创建数据库失败: {e}')
    import traceback
    traceback.print_exc()
" && db_initialized=true
    fi
    
    # 验证数据库是否成功创建
    if [ -f "app.db" ] && [ -s "app.db" ]; then
        log_success "数据库文件创建成功"
        
        # 设置正确的权限
        chown www-data:www-data app.db
        chmod 664 app.db
        
        # 显示数据库信息
        ls -la app.db
        
        # 验证表结构
        python3 -c "
import sqlite3
try:
    conn = sqlite3.connect('app.db')
    cursor = conn.cursor()
    cursor.execute(\"SELECT name FROM sqlite_master WHERE type='table'\")
    tables = cursor.fetchall()
    print('数据库表列表:')
    for table in tables:
        print(f'  - {table[0]}')
    conn.close()
except Exception as e:
    print(f'无法读取数据库表: {e}')
"
    else
        log_error "数据库初始化失败"
        if [ -f "app.db" ]; then
            log_warning "数据库文件存在但可能为空"
            ls -la app.db
        else
            log_error "数据库文件不存在"
        fi
    fi
    
    deactivate
    log_success "数据库初始化完成"
}

# 执行主函数
main