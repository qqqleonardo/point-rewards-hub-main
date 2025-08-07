#!/bin/bash

# 积分兑换平台问题排查脚本
# 使用方法: sudo bash troubleshoot-deployment.sh

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 域名配置
MOBILE_DOMAIN="points.eternalmoon.com.cn"
ADMIN_DOMAIN="dashboard.eternalmoon.com.cn"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

check_section() {
    echo ""
    echo "============================================"
    echo "  $1"
    echo "============================================"
}

# 1. 检查服务状态
check_services() {
    check_section "1. 检查服务状态"
    
    # 检查Nginx状态
    if systemctl is-active --quiet nginx; then
        log_success "Nginx 服务运行正常"
    else
        log_error "Nginx 服务未运行"
        systemctl status nginx --no-pager
    fi
    
    # 检查后端服务
    if supervisorctl status point-rewards-backend >/dev/null 2>&1; then
        backend_status=$(supervisorctl status point-rewards-backend | awk '{print $2}')
        if [ "$backend_status" = "RUNNING" ]; then
            log_success "后端服务运行正常"
        else
            log_error "后端服务状态异常: $backend_status"
        fi
    else
        log_error "后端服务未配置或未运行"
    fi
    
    # 检查Supervisor状态
    if systemctl is-active --quiet supervisor; then
        log_success "Supervisor 服务运行正常"
    else
        log_error "Supervisor 服务未运行"
    fi
}

# 2. 检查端口监听
check_ports() {
    check_section "2. 检查端口监听"
    
    # 检查80端口
    if netstat -tlnp 2>/dev/null | grep -q ":80 " || ss -tlnp 2>/dev/null | grep -q ":80 "; then
        log_success "端口 80 正在监听"
        netstat -tlnp 2>/dev/null | grep ":80 " || ss -tlnp 2>/dev/null | grep ":80 "
    else
        log_error "端口 80 未监听"
    fi
    
    # 检查443端口
    if netstat -tlnp 2>/dev/null | grep -q ":443 " || ss -tlnp 2>/dev/null | grep -q ":443 "; then
        log_success "端口 443 正在监听"
        netstat -tlnp 2>/dev/null | grep ":443 " || ss -tlnp 2>/dev/null | grep ":443 "
    else
        log_warning "端口 443 未监听 (如果没有SSL证书这是正常的)"
    fi
    
    # 检查5000端口（后端API）
    if netstat -tlnp 2>/dev/null | grep -q ":5000 " || ss -tlnp 2>/dev/null | grep -q ":5000 "; then
        log_success "端口 5000 正在监听 (后端API)"
        netstat -tlnp 2>/dev/null | grep ":5000 " || ss -tlnp 2>/dev/null | grep ":5000 "
    else
        log_error "端口 5000 未监听 (后端API未启动)"
    fi
}

# 3. 检查Nginx配置
check_nginx_config() {
    check_section "3. 检查Nginx配置"
    
    # 测试Nginx配置语法
    if nginx -t >/dev/null 2>&1; then
        log_success "Nginx 配置语法正确"
    else
        log_error "Nginx 配置语法错误:"
        nginx -t
    fi
    
    # 检查配置文件是否存在
    if [ -f "/etc/nginx/sites-available/point-rewards" ]; then
        log_success "Nginx 配置文件存在"
    else
        log_error "Nginx 配置文件不存在: /etc/nginx/sites-available/point-rewards"
    fi
    
    if [ -L "/etc/nginx/sites-enabled/point-rewards" ]; then
        log_success "Nginx 配置已启用"
    else
        log_error "Nginx 配置未启用"
        echo "  运行: sudo ln -s /etc/nginx/sites-available/point-rewards /etc/nginx/sites-enabled/"
    fi
    
    # 检查是否有默认站点冲突
    if [ -f "/etc/nginx/sites-enabled/default" ]; then
        log_warning "默认Nginx站点仍然启用，可能造成冲突"
        echo "  运行: sudo rm /etc/nginx/sites-enabled/default"
    else
        log_success "默认站点已禁用"
    fi
    
    # 显示当前监听的server_name
    if [ -f "/etc/nginx/sites-available/point-rewards" ]; then
        echo ""
        echo "当前配置的域名："
        grep "server_name" /etc/nginx/sites-available/point-rewards || echo "  未找到server_name配置"
    fi
}

# 4. 检查文件目录
check_file_directories() {
    check_section "4. 检查文件目录"
    
    # 检查Web根目录
    if [ -d "/var/www/$MOBILE_DOMAIN" ]; then
        log_success "移动端目录存在: /var/www/$MOBILE_DOMAIN"
        file_count=$(find "/var/www/$MOBILE_DOMAIN" -type f | wc -l)
        echo "  文件数量: $file_count"
        
        if [ -f "/var/www/$MOBILE_DOMAIN/index.html" ]; then
            log_success "index.html 文件存在"
        else
            log_error "index.html 文件不存在"
        fi
    else
        log_error "移动端目录不存在: /var/www/$MOBILE_DOMAIN"
    fi
    
    if [ -d "/var/www/$ADMIN_DOMAIN" ]; then
        log_success "管理后台目录存在: /var/www/$ADMIN_DOMAIN"
        file_count=$(find "/var/www/$ADMIN_DOMAIN" -type f | wc -l)
        echo "  文件数量: $file_count"
        
        if [ -f "/var/www/$ADMIN_DOMAIN/index.html" ]; then
            log_success "管理后台 index.html 文件存在"
        else
            log_error "管理后台 index.html 文件不存在"
        fi
    else
        log_error "管理后台目录不存在: /var/www/$ADMIN_DOMAIN"
    fi
    
    # 检查文件权限
    if [ -d "/var/www/$MOBILE_DOMAIN" ]; then
        owner=$(ls -ld "/var/www/$MOBILE_DOMAIN" | awk '{print $3":"$4}')
        if [ "$owner" = "www-data:www-data" ]; then
            log_success "文件权限正确: $owner"
        else
            log_warning "文件权限可能有问题: $owner"
            echo "  应该运行: sudo chown -R www-data:www-data /var/www/$MOBILE_DOMAIN"
        fi
    fi
}

# 5. 检查SSL证书
check_ssl_certificates() {
    check_section "5. 检查SSL证书"
    
    # 检查Let's Encrypt证书
    if command -v certbot >/dev/null 2>&1; then
        if certbot certificates 2>/dev/null | grep -q "$MOBILE_DOMAIN"; then
            log_success "Let's Encrypt证书存在"
            certbot certificates 2>/dev/null | grep -A 5 "$MOBILE_DOMAIN"
        else
            log_warning "Let's Encrypt证书不存在"
        fi
    else
        log_warning "certbot 未安装"
    fi
    
    # 检查自签名证书
    if [ -f "/etc/ssl/certs/$MOBILE_DOMAIN.crt" ]; then
        log_success "自签名证书存在"
        echo "  证书路径: /etc/ssl/certs/$MOBILE_DOMAIN.crt"
        
        # 检查证书有效期
        if openssl x509 -in "/etc/ssl/certs/$MOBILE_DOMAIN.crt" -noout -dates 2>/dev/null; then
            echo "  证书有效期:"
            openssl x509 -in "/etc/ssl/certs/$MOBILE_DOMAIN.crt" -noout -dates 2>/dev/null
        fi
    else
        log_warning "自签名证书不存在"
    fi
}

# 6. 检查防火墙
check_firewall() {
    check_section "6. 检查防火墙"
    
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            log_info "UFW防火墙已启用"
            echo "当前规则:"
            ufw status numbered
            
            if ufw status | grep -q "80/tcp"; then
                log_success "端口 80 已开放"
            else
                log_error "端口 80 未开放"
                echo "  运行: sudo ufw allow 80/tcp"
            fi
            
            if ufw status | grep -q "443/tcp"; then
                log_success "端口 443 已开放"
            else
                log_warning "端口 443 未开放"
                echo "  运行: sudo ufw allow 443/tcp"
            fi
        else
            log_info "UFW防火墙未启用"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        log_info "使用 firewalld"
        firewall-cmd --list-all
    else
        log_info "未检测到常见防火墙工具"
    fi
}

# 7. 网络连通性测试
test_connectivity() {
    check_section "7. 网络连通性测试"
    
    # 测试本地访问
    log_info "测试本地HTTP访问..."
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost" | grep -q "200\|301\|302"; then
        log_success "本地HTTP访问正常"
    else
        log_error "本地HTTP访问失败"
    fi
    
    # 测试域名访问（如果DNS解析正常）
    log_info "测试域名HTTP访问..."
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://$MOBILE_DOMAIN" 2>/dev/null || echo "000")
    if [ "$http_code" != "000" ]; then
        log_success "域名HTTP访问返回状态码: $http_code"
    else
        log_error "域名HTTP访问失败（可能是DNS问题）"
    fi
    
    # 测试HTTPS访问
    if [ -f "/etc/ssl/certs/$MOBILE_DOMAIN.crt" ] || certbot certificates 2>/dev/null | grep -q "$MOBILE_DOMAIN"; then
        log_info "测试HTTPS访问..."
        https_code=$(curl -s -k -o /dev/null -w "%{http_code}" "https://$MOBILE_DOMAIN" 2>/dev/null || echo "000")
        if [ "$https_code" != "000" ]; then
            log_success "HTTPS访问返回状态码: $https_code"
        else
            log_error "HTTPS访问失败"
        fi
    fi
    
    # 测试后端API
    log_info "测试后端API..."
    api_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:5000" 2>/dev/null || echo "000")
    if [ "$api_code" != "000" ]; then
        log_success "后端API访问返回状态码: $api_code"
    else
        log_error "后端API访问失败"
    fi
}

# 8. 查看日志
check_logs() {
    check_section "8. 查看最近日志"
    
    echo "=== Nginx 错误日志 (最近10行) ==="
    if [ -f "/var/log/nginx/error.log" ]; then
        tail -10 /var/log/nginx/error.log 2>/dev/null || echo "日志为空或无权限访问"
    else
        echo "错误日志文件不存在"
    fi
    
    echo ""
    echo "=== 后端错误日志 (最近10行) ==="
    if [ -f "/var/log/point-rewards-backend-error.log" ]; then
        tail -10 /var/log/point-rewards-backend-error.log 2>/dev/null || echo "日志为空或无权限访问"
    else
        echo "后端错误日志文件不存在"
    fi
    
    echo ""
    echo "=== 系统日志中的nginx相关信息 (最近5条) ==="
    journalctl -u nginx --no-pager -n 5 2>/dev/null || echo "无法访问系统日志"
}

# 9. 建议修复方案
suggest_fixes() {
    check_section "9. 常见问题修复建议"
    
    echo "如果发现问题，请尝试以下修复方案："
    echo ""
    echo "1. 重启服务："
    echo "   sudo systemctl restart nginx"
    echo "   sudo supervisorctl restart point-rewards-backend"
    echo ""
    echo "2. 如果Nginx配置有问题："
    echo "   cd /path/to/project"
    echo "   sudo bash deploy.sh  # 重新运行部署脚本"
    echo ""
    echo "3. 如果文件权限有问题："
    echo "   sudo chown -R www-data:www-data /var/www/$MOBILE_DOMAIN"
    echo "   sudo chmod -R 755 /var/www/$MOBILE_DOMAIN"
    echo ""
    echo "4. 如果端口被占用："
    echo "   sudo netstat -tlnp | grep :80"
    echo "   # 找到占用进程并关闭"
    echo ""
    echo "5. 如果DNS问题："
    echo "   在域名管理面板添加A记录："
    echo "   $MOBILE_DOMAIN     A    $(curl -s ifconfig.me || echo 'YOUR_SERVER_IP')"
    echo ""
    echo "6. 查看详细错误："
    echo "   sudo tail -f /var/log/nginx/error.log"
    echo "   sudo tail -f /var/log/point-rewards-backend-error.log"
}

# 主函数
main() {
    echo "=========================================="
    echo "    积分兑换平台问题排查脚本"
    echo "=========================================="
    echo "检查域名: $MOBILE_DOMAIN"
    echo "检查域名: $ADMIN_DOMAIN"
    echo ""
    
    check_services
    check_ports
    check_nginx_config
    check_file_directories
    check_ssl_certificates
    check_firewall
    test_connectivity
    check_logs
    suggest_fixes
    
    echo ""
    echo "=========================================="
    echo "           排查完成"
    echo "=========================================="
}

# 检查权限
if [[ $EUID -ne 0 ]]; then
    log_warning "建议使用 sudo 运行以获取完整信息"
    echo ""
fi

# 执行主函数
main "$@"