#!/bin/bash

# 积分兑换平台快速部署脚本 - eternalmoon.tech
# 使用方法: sudo bash deploy.sh

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 域名配置
MOBILE_DOMAIN="points.eternalmoon.tech"
ADMIN_DOMAIN="dashboard.eternalmoon.tech"
BASE_DOMAIN="eternalmoon.tech"

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
    
    # 创建虚拟环境
    python3 -m venv venv
    source venv/bin/activate
    
    # 安装依赖
    pip install -r requirements.txt
    
    # 创建环境变量文件
    cat > .env << EOF
SECRET_KEY=$(openssl rand -hex 32)
JWT_SECRET_KEY=$(openssl rand -hex 32)
DATABASE_URL=sqlite:///app.db
FLASK_ENV=production
EOF
    
    # 初始化数据库
    if [ -f "create_admin.py" ]; then
        log_info "请稍后手动创建管理员账户："
        log_info "cd /opt/point-rewards/point-rewards-backend && source venv/bin/activate && python create_admin.py"
    fi
    
    deactivate
    log_success "后端部署完成"
}

# 配置 Supervisor
configure_supervisor() {
    log_info "配置 Supervisor..."
    cat > /etc/supervisor/conf.d/point-rewards-backend.conf << EOF
[program:point-rewards-backend]
command=/opt/point-rewards/point-rewards-backend/venv/bin/python run.py
directory=/opt/point-rewards/point-rewards-backend
user=www-data
autostart=true
autorestart=true
stdout_logfile=/var/log/point-rewards-backend.log
stderr_logfile=/var/log/point-rewards-backend-error.log
environment=PYTHONPATH=/opt/point-rewards/point-rewards-backend
EOF
    
    supervisorctl reread
    supervisorctl update
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
        proxy_Set_header X-Forwarded-Proto \$scheme;
    }
    
    location /static {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_Set_header X-Real-IP \$remote_addr;
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
        proxy_Set_header X-Forwarded-Proto \$scheme;
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
        proxy_Set_header X-Real-IP \$remote_addr;
        proxy_Set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_Set_header X-Forwarded-Proto \$scheme;
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
    
    # 添加到 crontab
    (crontab -l 2>/dev/null; echo "0 2 * * * /opt/backup-db.sh") | crontab -
    
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
    log_success "eternalmoon.tech 积分兑换平台部署完成！"
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
    echo ""
    echo "下一步:"
    echo "1. 创建管理员账户:"
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
    echo "   eternalmoon.tech 积分兑换平台自动部署"
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
    verify_deployment
    show_deployment_info
    
    log_success "部署脚本执行完成！"
}

# 执行主函数
main