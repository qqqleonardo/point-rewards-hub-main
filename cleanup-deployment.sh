#!/bin/bash

# 积分兑换平台完整清理脚本
# 用于清理所有 eternalmoon 相关域名的部署文件
# 支持: .tech, .com, .com.cn 等所有后缀
# 使用方法: sudo bash cleanup-deployment.sh

set -e  # 遇到错误继续执行，但会显示错误信息

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 所有可能的eternalmoon域名模式
DOMAIN_PATTERNS=(
    "eternalmoon.tech"
    "eternalmoon.com"
    "eternalmoon.com.cn"
    "points.eternalmoon.tech"
    "points.eternalmoon.com"
    "points.eternalmoon.com.cn"
    "dashboard.eternalmoon.tech"
    "dashboard.eternalmoon.com"
    "dashboard.eternalmoon.com.cn"
)

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
    echo "   积分兑换平台完整清理脚本"
    echo "=========================================="
    echo ""
    echo "此脚本将清理所有 eternalmoon 相关的部署内容："
    echo ""
    echo "📁 项目目录:"
    echo "  - /opt/point-rewards"
    echo "  - /opt/backups"
    echo "  - /opt/point-rewards-deploy"
    echo ""
    echo "🌐 所有域名的Web目录:"
    for domain in "${DOMAIN_PATTERNS[@]}"; do
        if [[ "$domain" == points.* ]] || [[ "$domain" == dashboard.* ]]; then
            echo "  - /var/www/$domain"
        fi
    done
    echo ""
    echo "⚙️ 配置文件:"
    echo "  - Nginx: /etc/nginx/sites-*/point-rewards"
    echo "  - Supervisor: /etc/supervisor/conf.d/point-rewards-*"
    echo ""
    echo "📜 脚本和工具:"
    echo "  - /opt/backup-db.sh"
    echo "  - /opt/renew-ssl.sh"
    echo "  - /opt/start-backend-manual.sh"
    echo ""
    echo "📋 日志文件:"
    echo "  - /var/log/point-rewards-*"
    echo "  - /var/log/ssl-renewal.log"
    echo ""
    echo "🔒 所有域名的SSL证书"
    echo ""
    echo "⏰ 定时任务 (需要手动确认删除)"
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
    
    # 停止所有可能的后端服务
    for service in "point-rewards-backend" "point-rewards" "eternalmoon-backend"; do
        if supervisorctl status "$service" >/dev/null 2>&1; then
            supervisorctl stop "$service" || log_warning "无法停止 $service 服务"
            log_success "已停止 $service 服务"
        fi
    done
}

# 删除项目目录
cleanup_directories() {
    log_info "清理项目目录..."
    
    # 删除所有相关目录
    directories_to_remove=(
        "/opt/point-rewards"
        "/opt/backups"
        "/opt/point-rewards-deploy"
    )
    
    # 删除所有域名的Web目录
    for domain in "${DOMAIN_PATTERNS[@]}"; do
        if [[ "$domain" == points.* ]] || [[ "$domain" == dashboard.* ]]; then
            directories_to_remove+=("/var/www/$domain")
        fi
    done
    
    for dir in "${directories_to_remove[@]}"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            log_success "已删除 $dir"
        else
            log_info "$dir 目录不存在"
        fi
    done
}

# 删除配置文件
cleanup_configs() {
    log_info "清理配置文件..."
    
    # Nginx配置文件
    config_files=(
        "/etc/nginx/sites-available/point-rewards"
        "/etc/nginx/sites-available/eternalmoon"
        "/etc/nginx/sites-enabled/point-rewards"
        "/etc/nginx/sites-enabled/eternalmoon"
    )
    
    for config in "${config_files[@]}"; do
        if [ -f "$config" ] || [ -L "$config" ]; then
            rm -f "$config"
            log_success "已删除 $config"
        else
            log_info "$config 不存在"
        fi
    done
    
    # Supervisor配置文件
    supervisor_configs=(
        "/etc/supervisor/conf.d/point-rewards-backend.conf"
        "/etc/supervisor/conf.d/point-rewards.conf"
        "/etc/supervisor/conf.d/eternalmoon.conf"
    )
    
    for config in "${supervisor_configs[@]}"; do
        if [ -f "$config" ]; then
            rm -f "$config"
            log_success "已删除 Supervisor 配置: $(basename $config)"
        else
            log_info "Supervisor 配置不存在: $(basename $config)"
        fi
    done
}

# 删除脚本文件
cleanup_scripts() {
    log_info "清理脚本文件..."
    
    scripts_to_remove=(
        "/opt/backup-db.sh"
        "/opt/renew-ssl.sh"
        "/opt/start-backend-manual.sh"
        "/opt/point-rewards/start-backend-manual.sh"
    )
    
    for script in "${scripts_to_remove[@]}"; do
        if [ -f "$script" ]; then
            rm -f "$script"
            log_success "已删除脚本: $(basename $script)"
        else
            log_info "脚本不存在: $(basename $script)"
        fi
    done
}

# 删除日志文件
cleanup_logs() {
    log_info "清理日志文件..."
    
    log_files=(
        "/var/log/point-rewards-backend.log"
        "/var/log/point-rewards-backend-error.log"
        "/var/log/ssl-renewal.log"
        "/var/log/eternalmoon.log"
        "/var/log/eternalmoon-error.log"
    )
    
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            rm -f "$log_file"
            log_success "已删除日志: $(basename $log_file)"
        else
            log_info "日志不存在: $(basename $log_file)"
        fi
    done
}

# 删除SSL证书
cleanup_ssl_certificates() {
    log_info "清理SSL证书..."
    
    # 删除Let's Encrypt证书
    if command -v certbot >/dev/null 2>&1; then
        for domain in "${DOMAIN_PATTERNS[@]}"; do
            if certbot certificates 2>/dev/null | grep -q "$domain"; then
                certbot delete --cert-name "$domain" --non-interactive 2>/dev/null || log_warning "无法删除 $domain 证书"
                log_success "已删除 $domain Let's Encrypt 证书"
            fi
        done
    else
        log_info "certbot 未安装，跳过 Let's Encrypt 证书清理"
    fi
    
    # 删除自签名证书
    for domain in "${DOMAIN_PATTERNS[@]}"; do
        cert_files=(
            "/etc/ssl/certs/$domain.crt"
            "/etc/ssl/private/$domain.key"
        )
        
        for cert_file in "${cert_files[@]}"; do
            if [ -f "$cert_file" ]; then
                rm -f "$cert_file"
                log_success "已删除自签名证书: $(basename $cert_file)"
            fi
        done
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
    if crontab -l 2>/dev/null | grep -E "(backup-db|renew-ssl|point-rewards|eternalmoon)" >/dev/null; then
        log_warning "发现相关的定时任务，请手动清理："
        echo ""
        echo "运行以下命令编辑定时任务："
        echo "  sudo crontab -e"
        echo ""
        echo "删除包含以下关键词的行："
        echo "  - backup-db.sh"
        echo "  - renew-ssl.sh"
        echo "  - point-rewards"
        echo "  - eternalmoon"
        echo ""
        crontab -l 2>/dev/null | grep -E "(backup-db|renew-ssl|point-rewards|eternalmoon)" | sed 's/^/  /'
        echo ""
    else
        log_success "未发现相关的定时任务"
    fi
}

# 显示清理结果
show_cleanup_summary() {
    echo ""
    echo "=========================================="
    log_success "完整部署清理完成！"
    echo "=========================================="
    echo ""
    echo "已清理的内容："
    echo "  ✓ 所有项目目录和Web文件"
    echo "  ✓ 所有域名配置 (.tech, .com, .com.cn)"
    echo "  ✓ Nginx和Supervisor配置"
    echo "  ✓ 备份和续期脚本"
    echo "  ✓ 所有日志文件"
    echo "  ✓ 所有域名的SSL证书"
    echo "  ✓ 服务配置已重新加载"
    echo ""
    echo "后续步骤："
    echo "1. 如有定时任务需要手动清理，请运行: sudo crontab -e"
    echo "2. 检查端口占用: sudo netstat -tlnp | grep 5000"
    echo "3. 现在可以重新部署新版本"
    echo ""
    echo "重新部署命令："
    echo "  sudo bash deploy.sh          # 标准部署"
    echo "  sudo bash deploy-robust.sh   # 增强部署"
    echo ""
    echo "=========================================="
}

# 主函数
main() {
    check_root
    confirm_cleanup
    
    echo ""
    log_info "开始清理所有 eternalmoon 相关的部署文件..."
    
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