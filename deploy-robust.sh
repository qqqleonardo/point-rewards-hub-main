#!/bin/bash

# 积分兑换平台增强部署脚本 - eternalmoon.tech
# 支持断点续传和幂等性操作
# 使用方法: sudo bash deploy-robust.sh [--resume] [--force]

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

# 状态文件路径
STATE_DIR="/opt/point-rewards-deploy"
STATE_FILE="$STATE_DIR/deploy.state"
LOG_FILE="$STATE_DIR/deploy.log"

# 部署步骤列表
DEPLOY_STEPS=(
    "check_prerequisites"
    "update_system" 
    "install_packages"
    "create_directories"
    "copy_project_files"
    "deploy_backend"
    "configure_supervisor"
    "deploy_frontend"
    "setup_ssl"
    "setup_nginx_https"
    "setup_firewall"
    "start_services"
    "setup_backup"
    "verify_deployment"
)

# 命令行参数
RESUME_MODE=false
FORCE_MODE=false

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --resume)
                RESUME_MODE=true
                shift
                ;;
            --force)
                FORCE_MODE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 显示帮助信息
show_help() {
    echo "用法: sudo bash deploy-robust.sh [选项]"
    echo ""
    echo "选项:"
    echo "  --resume    从上次失败的步骤继续部署"
    echo "  --force     强制重新执行所有步骤"
    echo "  -h, --help  显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  sudo bash deploy-robust.sh         # 全新部署"
    echo "  sudo bash deploy-robust.sh --resume # 断点续传"
    echo "  sudo bash deploy-robust.sh --force  # 强制重新部署"
}

# 日志函数
log_with_timestamp() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log_with_timestamp "INFO" "$1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log_with_timestamp "SUCCESS" "$1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log_with_timestamp "WARNING" "$1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log_with_timestamp "ERROR" "$1"
}

# 状态管理函数
init_state() {
    mkdir -p "$STATE_DIR"
    touch "$STATE_FILE"
    touch "$LOG_FILE"
    
    if [[ "$FORCE_MODE" == true ]]; then
        log_info "强制模式：清除所有状态"
        > "$STATE_FILE"
    fi
}

mark_step_complete() {
    local step=$1
    echo "$step=completed" >> "$STATE_FILE"
    log_success "步骤完成: $step"
}

is_step_completed() {
    local step=$1
    grep -q "^${step}=completed$" "$STATE_FILE" 2>/dev/null
}

get_next_step() {
    for step in "${DEPLOY_STEPS[@]}"; do
        if ! is_step_completed "$step"; then
            echo "$step"
            return
        fi
    done
    echo ""
}

show_progress() {
    local completed=0
    local total=${#DEPLOY_STEPS[@]}
    
    for step in "${DEPLOY_STEPS[@]}"; do
        if is_step_completed "$step"; then
            ((completed++))
        fi
    done
    
    echo "部署进度: $completed/$total 步骤完成"
    
    if [[ $completed -gt 0 ]]; then
        echo "已完成的步骤:"
        for step in "${DEPLOY_STEPS[@]}"; do
            if is_step_completed "$step"; then
                echo "  ✓ $step"
            else
                echo "  ○ $step"
            fi
        done
    fi
}

# 检查是否以 root 权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限运行，请使用 sudo"
        exit 1
    fi
}

# 检查先决条件
check_prerequisites() {
    log_info "检查先决条件..."
    
    # 检查项目文件是否存在
    if [ ! -d "point-rewards-backend" ] || [ ! -d "point-rewards-frontend" ] || [ ! -d "point-rewards-admin-web" ]; then
        log_error "请在项目根目录下运行此脚本"
        log_error "确保存在以下目录: point-rewards-backend, point-rewards-frontend, point-rewards-admin-web"
        exit 1
    fi
    
    # 检查网络连接
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_warning "网络连接异常，可能影响包安装"
    fi
    
    mark_step_complete "check_prerequisites"
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
    if is_step_completed "update_system" && [[ "$FORCE_MODE" != true ]]; then
        log_info "跳过系统更新（已完成）"
        return
    fi
    
    log_info "更新系统包..."
    detect_system
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        apt update && apt upgrade -y
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        yum update -y
    else
        log_warning "未知系统类型，跳过系统更新"
    fi
    
    mark_step_complete "update_system"
}

# 安装基础软件
install_packages() {
    if is_step_completed "install_packages" && [[ "$FORCE_MODE" != true ]]; then
        log_info "跳过软件包安装（已完成）"
        return
    fi
    
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
    
    mark_step_complete "install_packages"
}

# 创建项目目录
create_directories() {
    if is_step_completed "create_directories" && [[ "$FORCE_MODE" != true ]]; then
        log_info "跳过目录创建（已完成）"
        return
    fi
    
    log_info "创建项目目录..."
    mkdir -p /opt/point-rewards
    mkdir -p /var/www/$MOBILE_DOMAIN
    mkdir -p /var/www/$ADMIN_DOMAIN
    mkdir -p /opt/backups
    mkdir -p /var/log
    
    mark_step_complete "create_directories"
}

# 复制项目文件
copy_project_files() {
    if is_step_completed "copy_project_files" && [[ "$FORCE_MODE" != true ]]; then
        log_info "跳过项目文件复制（已完成）"
        return
    fi
    
    log_info "复制项目文件到 /opt/point-rewards..."
    cp -r . /opt/point-rewards/
    
    mark_step_complete "copy_project_files"
}

# 部署后端
deploy_backend() {
    if is_step_completed "deploy_backend" && [[ "$FORCE_MODE" != true ]]; then
        log_info "跳过后端部署（已完成）"
        return
    fi
    
    log_info "部署后端服务..."
    cd /opt/point-rewards/point-rewards-backend
    
    # 创建虚拟环境（如果不存在）
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    
    # 安装依赖
    pip install -r requirements.txt
    
    # 创建环境变量文件（如果不存在）
    if [ ! -f ".env" ]; then
        cat > .env << EOF
SECRET_KEY=$(openssl rand -hex 32)
JWT_SECRET_KEY=$(openssl rand -hex 32)
DATABASE_URL=sqlite:///app.db
FLASK_ENV=production
EOF
    fi
    
    # 初始化数据库
    if [ -f "utils/create_admin.py" ]; then
        log_info "请稍后手动创建管理员账户："
        log_info "cd /opt/point-rewards/point-rewards-backend && source venv/bin/activate && python utils/create_admin.py"
    fi
    
    deactivate
    mark_step_complete "deploy_backend"
}

# 配置 Supervisor
configure_supervisor() {
    if is_step_completed "configure_supervisor" && [[ "$FORCE_MODE" != true ]]; then
        log_info "跳过 Supervisor 配置（已完成）"
        return
    fi
    
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
    mark_step_complete "configure_supervisor"
}

# 部署前端
deploy_frontend() {
    if is_step_completed "deploy_frontend" && [[ "$FORCE_MODE" != true ]]; then
        log_info "跳过前端部署（已完成）"
        return
    fi
    
    log_info "部署移动端前端..."
    cd /opt/point-rewards/point-rewards-frontend
    
    # 检查 Node.js 版本
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 16 ]; then
        log_warning "Node.js 版本过低，建议升级到 16+ 版本"
    fi
    
    # 检查是否已经构建过
    if [ ! -d "node_modules" ]; then
        npm install
    fi
    
    if [ ! -d "dist" ] || [[ "$FORCE_MODE" == true ]]; then
        npm run build
    fi
    
    # 复制构建文件
    cp -r dist/* /var/www/$MOBILE_DOMAIN/
    
    log_info "部署管理后台..."
    cd /opt/point-rewards/point-rewards-admin-web
    
    if [ ! -d "node_modules" ]; then
        npm install
    fi
    
    if [ ! -d "dist" ] || [[ "$FORCE_MODE" == true ]]; then
        npm run build
    fi
    
    # 复制管理后台文件
    cp -r dist/* /var/www/$ADMIN_DOMAIN/
    
    # 设置权限
    chown -R www-data:www-data /var/www/$MOBILE_DOMAIN
    chown -R www-data:www-data /var/www/$ADMIN_DOMAIN
    chmod -R 755 /var/www/$MOBILE_DOMAIN
    chmod -R 755 /var/www/$ADMIN_DOMAIN
    
    mark_step_complete "deploy_frontend"
}

# 获取 SSL 证书
setup_ssl() {
    if is_step_completed "setup_ssl" && [[ "$FORCE_MODE" != true ]]; then
        log_info "跳过 SSL 设置（已完成）"
        return
    fi
    
    log_info "设置 SSL 证书..."
    
    # 先启动 nginx 基础配置
    setup_nginx_basic
    
    # 获取 Let's Encrypt 证书
    if certbot --nginx -d $MOBILE_DOMAIN -d $ADMIN_DOMAIN --non-interactive --agree-tos --email admin@$BASE_DOMAIN --redirect; then
        log_success "SSL 证书获取成功"
    else
        log_warning "SSL 证书获取失败，将使用自签名证书"
        setup_self_signed_ssl
    fi
    
    mark_step_complete "setup_ssl"
}

# 创建自签名 SSL 证书（用于测试）
setup_self_signed_ssl() {
    log_info "创建自签名 SSL 证书..."
    mkdir -p /etc/ssl/private
    
    # 为移动端域名创建证书
    if [ ! -f "/etc/ssl/certs/$MOBILE_DOMAIN.crt" ]; then
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/ssl/private/$MOBILE_DOMAIN.key \
            -out /etc/ssl/certs/$MOBILE_DOMAIN.crt \
            -subj "/C=CN/ST=State/L=City/O=Organization/CN=$MOBILE_DOMAIN"
    fi
    
    # 为管理后台域名创建证书
    if [ ! -f "/etc/ssl/certs/$ADMIN_DOMAIN.crt" ]; then
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/ssl/private/$ADMIN_DOMAIN.key \
            -out /etc/ssl/certs/$ADMIN_DOMAIN.crt \
            -subj "/C=CN/ST=State/L=City/O=Organization/CN=$ADMIN_DOMAIN"
    fi
    
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
    if is_step_completed "setup_nginx_https" && [[ "$FORCE_MODE" != true ]]; then
        log_info "跳过 Nginx HTTPS 配置（已完成）"
        return
    fi
    
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
    mark_step_complete "setup_nginx_https"
}

# 配置防火墙
setup_firewall() {
    if is_step_completed "setup_firewall" && [[ "$FORCE_MODE" != true ]]; then
        log_info "跳过防火墙配置（已完成）"
        return
    fi
    
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
    
    mark_step_complete "setup_firewall"
}

# 启动服务
start_services() {
    if is_step_completed "start_services" && [[ "$FORCE_MODE" != true ]]; then
        log_info "跳过服务启动（已完成）"
        return
    fi
    
    log_info "启动所有服务..."
    
    # 启用并启动 supervisor
    systemctl enable supervisor
    systemctl start supervisor
    
    # 启动后端服务
    supervisorctl start point-rewards-backend
    
    # 启用并启动 nginx
    systemctl enable nginx
    systemctl start nginx
    
    mark_step_complete "start_services"
}

# 创建备份脚本
setup_backup() {
    if is_step_completed "setup_backup" && [[ "$FORCE_MODE" != true ]]; then
        log_info "跳过备份脚本设置（已完成）"
        return
    fi
    
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
    
    # 添加到 crontab（如果不存在）
    current_cron=$(crontab -l 2>/dev/null || echo "")
    
    if ! echo "$current_cron" | grep -q "/opt/backup-db.sh"; then
        current_cron="$current_cron"$'\n'"0 2 * * * /opt/backup-db.sh"
    fi
    
    if ! echo "$current_cron" | grep -q "/opt/renew-ssl.sh"; then
        current_cron="$current_cron"$'\n'"0 3 * * * /opt/renew-ssl.sh"
    fi
    
    echo "$current_cron" | crontab -
    
    mark_step_complete "setup_backup"
}

# 验证部署
verify_deployment() {
    if is_step_completed "verify_deployment" && [[ "$FORCE_MODE" != true ]]; then
        log_info "跳过部署验证（已完成）"
        return
    fi
    
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
    
    mark_step_complete "verify_deployment"
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
    echo "  部署状态: $STATE_FILE"
    echo "  部署日志: $LOG_FILE"
    echo ""
    echo "管理命令:"
    echo "  查看后端日志: sudo tail -f /var/log/point-rewards-backend.log"
    echo "  重启后端: sudo supervisorctl restart point-rewards-backend"
    echo "  重启 Nginx: sudo systemctl restart nginx"
    echo "  手动备份: sudo /opt/backup-db.sh"
    echo "  SSL证书续期: sudo /opt/renew-ssl.sh"
    echo "  查看SSL续期日志: sudo tail -f /var/log/ssl-renewal.log"
    echo "  查看部署状态: cat $STATE_FILE"
    echo "  断点续传: sudo bash deploy-robust.sh --resume"
    echo ""
    echo "下一步:"
    echo "1. 创建管理员账户:"
    echo "   cd /opt/point-rewards/point-rewards-backend"
    echo "   source venv/bin/activate"
    echo "   python utils/create_admin.py"
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
    echo "   eternalmoon.tech 积分兑换平台增强部署"
    echo "=========================================="
    echo ""
    echo "将部署以下域名:"
    echo "  移动端: $MOBILE_DOMAIN"
    echo "  管理后台: $ADMIN_DOMAIN"
    echo ""
    
    parse_args "$@"
    check_root
    init_state
    
    if [[ "$RESUME_MODE" == true ]]; then
        log_info "断点续传模式"
        show_progress
        echo ""
    fi
    
    # 获取下一个要执行的步骤
    next_step=$(get_next_step)
    
    if [[ -z "$next_step" ]]; then
        log_success "所有部署步骤均已完成！"
        show_deployment_info
        exit 0
    fi
    
    if [[ "$RESUME_MODE" != true ]]; then
        # 确认继续
        read -p "继续部署? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "部署已取消"
            exit 0
        fi
    fi
    
    # 执行部署步骤
    for step in "${DEPLOY_STEPS[@]}"; do
        if ! is_step_completed "$step" || [[ "$FORCE_MODE" == true ]]; then
            log_info "执行步骤: $step"
            eval "$step"
        fi
    done
    
    show_deployment_info
    log_success "部署脚本执行完成！"
}

# 错误处理
trap 'log_error "部署过程中发生错误，在第 $LINENO 行。使用 --resume 参数可从失败点继续。"' ERR

# 执行主函数
main "$@"