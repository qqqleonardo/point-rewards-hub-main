#!/bin/bash

# 积分兑换平台旧部署清理脚本
# 用于清理基于 eternalmoon.tech 域名的旧部署文件
# 使用方法: sudo bash cleanup-old-deployment.sh

set -e  # 遇到错误继续执行，但会显示错误信息

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 确认清理操作
confirm_cleanup() {
    echo "=========================================="
    echo "   积分兑换平台旧部署清理脚本"
    echo "=========================================="
    echo ""
    echo "此脚本将清理以下内容："
    echo "  - 项目目录: /opt/point-rewards"
    echo "  - 旧域名Web目录: /var/www/points.eternalmoon.tech"
    echo "  - 旧域名Web目录: /var/www/dashboard.eternalmoon.tech"
    echo "  - 备份目录: /opt/backups"
    echo "  - Nginx配置: /etc/nginx/sites-*/point-rewards"
    echo "  - Supervisor配置: /etc/supervisor/conf.d/point-rewards-backend.conf"
    echo "  - 相关脚本和日志文件"
    echo "  - 旧域名SSL证书"
    echo ""
    log_warning "注意：此操作不可撤销！"
    echo ""
    
    read -p "确认继续清理? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "清理已取消"
        exit 0
    fi
}

# 停止服务
stop_services() {
    log_info "停止相关服务..."
    
    # 停止后端服务
    if supervisorctl status point-rewards-backend >/dev/null 2>&1; then
        supervisorctl stop point-rewards-backend || log_warning "无法停止 point-rewards-backend 服务"
        log_success "已停止 point-rewards-backend 服务"
    else
        log_info "point-rewards-backend 服务未运行"
    fi
}

# 删除项目目录
cleanup_directories() {
    log_info "清理项目目录..."
    
    # 删除主项目目录
    if [ -d "/opt/point-rewards" ]; then
        rm -rf /opt/point-rewards
        log_success "已删除 /opt/point-rewards"
    else
        log_info "/opt/point-rewards 目录不存在"
    fi
    
    # 删除旧域名Web目录
    if [ -d "/var/www/points.eternalmoon.tech" ]; then
        rm -rf /var/www/points.eternalmoon.tech
        log_success "已删除 /var/www/points.eternalmoon.tech"
    else
        log_info "/var/www/points.eternalmoon.tech 目录不存在"
    fi
    
    if [ -d "/var/www/dashboard.eternalmoon.tech" ]; then
        rm -rf /var/www/dashboard.eternalmoon.tech
        log_success "已删除 /var/www/dashboard.eternalmoon.tech"
    else
        log_info "/var/www/dashboard.eternalmoon.tech 目录不存在"
    fi
    
    # 删除备份目录
    if [ -d "/opt/backups" ]; then
        rm -rf /opt/backups
        log_success "已删除 /opt/backups"
    else
        log_info "/opt/backups 目录不存在"
    fi
    
    # 删除部署状态目录
    if [ -d "/opt/point-rewards-deploy" ]; then
        rm -rf /opt/point-rewards-deploy
        log_success "已删除 /opt/point-rewards-deploy"
    else
        log_info "/opt/point-rewards-deploy 目录不存在"
    fi
}

# 删除配置文件
cleanup_configs() {
    log_info "清理配置文件..."
    
    # 删除Nginx配置
    if [ -f "/etc/nginx/sites-available/point-rewards" ]; then
        rm -f /etc/nginx/sites-available/point-rewards
        log_success "已删除 Nginx 配置文件"
    else
        log_info "Nginx 配置文件不存在"
    fi
    
    if [ -L "/etc/nginx/sites-enabled/point-rewards" ]; then
        rm -f /etc/nginx/sites-enabled/point-rewards
        log_success "已删除 Nginx 启用配置链接"
    else
        log_info "Nginx 启用配置链接不存在"
    fi
    
    # 删除Supervisor配置
    if [ -f "/etc/supervisor/conf.d/point-rewards-backend.conf" ]; then
        rm -f /etc/supervisor/conf.d/point-rewards-backend.conf
        log_success "已删除 Supervisor 配置文件"
    else
        log_info "Supervisor 配置文件不存在"
    fi
}

# 删除脚本文件
cleanup_scripts() {
    log_info "清理脚本文件..."
    
    # 删除备份脚本
    if [ -f "/opt/backup-db.sh" ]; then
        rm -f /opt/backup-db.sh
        log_success "已删除备份脚本"
    else
        log_info "备份脚本不存在"
    fi
    
    # 删除SSL续期脚本
    if [ -f "/opt/renew-ssl.sh" ]; then
        rm -f /opt/renew-ssl.sh
        log_success "已删除SSL续期脚本"
    else
        log_info "SSL续期脚本不存在"
    fi
}

# 删除日志文件
cleanup_logs() {
    log_info "清理日志文件..."
    
    # 删除应用日志
    if [ -f "/var/log/point-rewards-backend.log" ]; then
        rm -f /var/log/point-rewards-backend.log
        log_success "已删除后端日志文件"
    else
        log_info "后端日志文件不存在"
    fi
    
    if [ -f "/var/log/point-rewards-backend-error.log" ]; then
        rm -f /var/log/point-rewards-backend-error.log
        log_success "已删除后端错误日志文件"
    else
        log_info "后端错误日志文件不存在"
    fi
    
    if [ -f "/var/log/ssl-renewal.log" ]; then
        rm -f /var/log/ssl-renewal.log
        log_success "已删除SSL续期日志文件"
    else
        log_info "SSL续期日志文件不存在"
    fi
}

# 删除SSL证书
cleanup_ssl_certificates() {
    log_info "清理SSL证书..."
    
    # 删除Let's Encrypt证书
    if command -v certbot >/dev/null 2>&1; then
        # 检查并删除points.eternalmoon.tech证书
        if certbot certificates 2>/dev/null | grep -q "points.eternalmoon.tech"; then
            certbot delete --cert-name points.eternalmoon.tech --non-interactive 2>/dev/null || log_warning "无法删除 points.eternalmoon.tech 证书"
            log_success "已删除 points.eternalmoon.tech Let's Encrypt 证书"
        else
            log_info "points.eternalmoon.tech Let's Encrypt 证书不存在"
        fi
        
        # 检查并删除dashboard.eternalmoon.tech证书
        if certbot certificates 2>/dev/null | grep -q "dashboard.eternalmoon.tech"; then
            certbot delete --cert-name dashboard.eternalmoon.tech --non-interactive 2>/dev/null || log_warning "无法删除 dashboard.eternalmoon.tech 证书"
            log_success "已删除 dashboard.eternalmoon.tech Let's Encrypt 证书"
        else
            log_info "dashboard.eternalmoon.tech Let's Encrypt 证书不存在"
        fi
    else
        log_info "certbot 未安装，跳过 Let's Encrypt 证书清理"
    fi
    
    # 删除自签名证书
    local self_signed_certs=(
        "/etc/ssl/certs/points.eternalmoon.tech.crt"
        "/etc/ssl/private/points.eternalmoon.tech.key"
        "/etc/ssl/certs/dashboard.eternalmoon.tech.crt"
        "/etc/ssl/private/dashboard.eternalmoon.tech.key"
    )
    
    for cert_file in "${self_signed_certs[@]}"; do
        if [ -f "$cert_file" ]; then
            rm -f "$cert_file"
            log_success "已删除自签名证书: $(basename $cert_file)"
        else
            log_info "自签名证书不存在: $(basename $cert_file)"
        fi
    done
}

# 重新加载服务配置
reload_services() {
    log_info "重新加载服务配置..."
    
    # 重新加载Supervisor配置
    if command -v supervisorctl >/dev/null 2>&1; then
        supervisorctl reread >/dev/null 2>&1 || log_warning "无法重新读取 Supervisor 配置"
        supervisorctl update >/dev/null 2>&1 || log_warning "无法更新 Supervisor 配置"
        log_success "已重新加载 Supervisor 配置"
    else
        log_info "Supervisor 未安装"
    fi
    
    # 重新加载Nginx配置
    if command -v nginx >/dev/null 2>&1; then
        if nginx -t >/dev/null 2>&1; then
            systemctl reload nginx >/dev/null 2>&1 || log_warning "无法重新加载 Nginx 配置"
            log_success "已重新加载 Nginx 配置"
        else
            log_warning "Nginx 配置测试失败，跳过重新加载"
        fi
    else
        log_info "Nginx 未安装"
    fi
}

# 检查剩余的定时任务
check_crontab() {
    log_info "检查定时任务..."
    
    # 检查root用户的crontab
    if crontab -l 2>/dev/null | grep -E "(backup-db|renew-ssl|point-rewards)" >/dev/null; then
        log_warning "发现相关的定时任务，请手动清理："
        echo ""
        echo "运行以下命令编辑定时任务："
        echo "  sudo crontab -e"
        echo ""
        echo "删除包含以下关键词的行："
        echo "  - backup-db.sh"
        echo "  - renew-ssl.sh"
        echo "  - point-rewards"
        echo ""
        crontab -l 2>/dev/null | grep -E "(backup-db|renew-ssl|point-rewards)" | sed 's/^/  /'
        echo ""
    else
        log_success "未发现相关的定时任务"
    fi
}

# 显示清理结果
show_cleanup_summary() {
    echo ""
    echo "=========================================="
    log_success "旧部署清理完成！"
    echo "=========================================="
    echo ""
    echo "已清理的内容："
    echo "  ✓ 项目目录和Web文件"
    echo "  ✓ Nginx和Supervisor配置"
    echo "  ✓ 备份和续期脚本"
    echo "  ✓ 日志文件"
    echo "  ✓ SSL证书"
    echo "  ✓ 服务配置已重新加载"
    echo ""
    echo "后续步骤："
    echo "1. 如有定时任务需要手动清理，请运行: sudo crontab -e"
    echo "2. 检查端口占用: sudo netstat -tlnp | grep 5000"
    echo "3. 现在可以使用新域名重新部署"
    echo ""
    echo "重新部署命令："
    echo "  sudo bash deploy.sh          # 快速部署"
    echo "  sudo bash deploy-robust.sh   # 增强部署"
    echo ""
    echo "=========================================="
}

# 主函数
main() {
    check_root
    confirm_cleanup
    
    echo ""
    log_info "开始清理旧的部署文件..."
    
    stop_services
    cleanup_directories
    cleanup_configs
    cleanup_scripts
    cleanup_logs
    cleanup_ssl_certificates
    reload_services
    check_crontab
    
    show_cleanup_summary
}

# 错误处理
trap 'log_error "清理过程中发生错误，在第 $LINENO 行。"' ERR

# 执行主函数
main "$@"