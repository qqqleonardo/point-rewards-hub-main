#!/bin/bash

# 积分兑换平台统一管理脚本
# 使用方法: bash manage.sh [command]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 检查命令是否可用
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 显示帮助信息
show_help() {
    echo "=========================================="
    echo "    积分兑换平台管理工具"
    echo "=========================================="
    echo ""
    echo "使用方法: bash manage.sh [命令]"
    echo ""
    echo "🚀 部署命令:"
    echo "  deploy          - 一键部署（推荐）"
    echo "  deploy-robust   - 增强部署（支持断点续传）"
    echo "  cleanup         - 完整清理所有部署文件"
    echo ""
    echo "🔧 维护命令:"
    echo "  init-db         - 初始化数据库"
    echo "  fix-db          - 修复数据库问题（自动创建表和管理员）"
    echo "  create-admin    - 创建管理员账户"
    echo "  backup          - 备份数据库"
    echo "  restart         - 重启所有服务"
    echo ""
    echo "🔍 诊断命令:"
    echo "  status          - 查看服务状态"
    echo "  logs            - 查看服务日志"
    echo "  test            - 测试网站访问"
    echo "  troubleshoot    - 运行故障排查"
    echo ""
    echo "📋 信息命令:"
    echo "  info            - 显示部署信息"
    echo "  view-data       - 查看数据库数据"
    echo "  help            - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  sudo bash manage.sh deploy        # 一键部署系统"
    echo "  bash manage.sh status             # 查看服务状态"  
    echo "  bash manage.sh test               # 测试网站访问"
    echo "  sudo bash manage.sh create-admin  # 创建管理员"
    echo "  sudo bash manage.sh fix-db        # 修复数据库问题"
    echo ""
    echo "=========================================="
}

# 检查权限
check_permissions() {
    if [[ "$1" == "deploy" ]] || [[ "$1" == "deploy-robust" ]] || [[ "$1" == "cleanup" ]] || [[ "$1" == "init-db" ]] || [[ "$1" == "fix-db" ]] || [[ "$1" == "restart" ]] || [[ "$1" == "backup" ]] || [[ "$1" == "create-admin" ]]; then
        if [[ $EUID -ne 0 ]]; then
            log_error "此命令需要 root 权限，请使用 sudo"
            exit 1
        fi
    fi
}

# 部署功能
deploy() {
    log_info "开始标准部署..."
    if [ -f "deploy.sh" ]; then
        bash deploy.sh
        log_info "部署脚本执行完毕，开始初始化数据库和管理员账户..."
        fix_database
    else
        log_error "部署脚本不存在"
        exit 1
    fi
}

deploy_robust() {
    log_info "开始增强部署..."
    if [ -f "deploy-robust.sh" ]; then
        bash deploy-robust.sh
        log_info "增强部署脚本执行完毕，开始初始化数据库和管理员账户..."
        fix_database
    else
        log_error "增强部署脚本不存在"
        exit 1
    fi
}

# 清理功能
cleanup() {
    log_info "开始清理部署..."
    if [ -f "cleanup-deployment.sh" ]; then
        bash cleanup-deployment.sh
    else
        log_error "清理脚本不存在"
        exit 1
    fi
}

# 初始化数据库
init_database() {
    log_info "初始化数据库..."
    cd /opt/point-rewards/point-rewards-backend 2>/dev/null || {
        log_error "后端目录不存在，请先运行部署"
        exit 1
    }
    
    if [ ! -d "venv" ]; then
        log_error "虚拟环境不存在，请先运行部署"
        exit 1
    fi
    
    source venv/bin/activate
    
    if command_exists python3; then
        python3 -c "
from app import create_app, db
app = create_app()
with app.app_context():
    db.create_all()
    print('数据库初始化成功')
"
    elif command_exists python; then
        python -c "
from app import create_app, db
app = create_app()
with app.app_context():
    db.create_all()
    print('数据库初始化成功')
"
    else
        log_error "未找到Python解释器"
        deactivate
        exit 1
    fi
    
    deactivate
}

# 修复数据库问题
fix_database() {
    log_info "修复数据库问题..."
    cd /opt/point-rewards/point-rewards-backend 2>/dev/null || {
        log_error "后端目录不存在，请先运行部署"
        exit 1
    }
    
    if [ ! -d "venv" ]; then
        log_error "虚拟环境不存在，请先运行部署"
        exit 1
    fi
    
    # 备份数据库
    if [ -f "app.db" ]; then
        backup_name="app_backup_$(date +%Y%m%d_%H%M%S).db"
        cp app.db "$backup_name"
        log_success "数据库已备份为: $backup_name"
    fi
    
    source venv/bin/activate
    
    local python_cmd=""
    if command_exists python3; then
        python_cmd="python3"
    elif command_exists python; then
        python_cmd="python"
    else
        log_error "未找到Python解释器"
        deactivate
        exit 1
    fi
    
    $python_cmd -c "
from app import create_app, db
from app.models import User

app = create_app()
with app.app_context():
    # 重新创建所有表
    db.drop_all()
    db.create_all()
    print('✅ 数据库表重新创建成功')
    
    # 创建管理员账户
    admin = User.query.filter_by(phone='admin').first()
    if not admin:
        admin = User(
            nickname='超级管理员',
            kuaishouId='admin001',
            phone='admin',
            points=1000,
            is_admin=True,
            addresses=[]
        )
        admin.set_password('Eternalmoon.com1')
        db.session.add(admin)
        db.session.commit()
        print('✅ 管理员账户创建成功')
        print('登录信息: admin / Eternalmoon.com1')
    else:
        print('✅ 管理员账户已存在')
"
    
    if [ $? -eq 0 ]; then
        log_success "数据库修复完成！"
        echo "管理员登录信息: admin / Eternalmoon.com1"
    else
        log_error "数据库修复失败"
    fi
    
    deactivate
}

# 创建管理员
create_admin() {
    log_info "创建管理员账户..."
    cd /opt/point-rewards/point-rewards-backend 2>/dev/null || {
        log_error "后端目录不存在，请先运行部署"
        exit 1
    }
    
    if [ ! -d "venv" ]; then
        log_error "虚拟环境不存在，请先运行部署"
        exit 1
    fi
    
    # 检查管理员脚本
    if [ -f "utils/create_admin_enhanced.py" ]; then
        source venv/bin/activate
        if command_exists python3; then
            python3 utils/create_admin_enhanced.py
        elif command_exists python; then
            python utils/create_admin_enhanced.py
        else
            log_error "未找到Python解释器"
            deactivate
            exit 1
        fi
        deactivate
    else
        # 备选方案：直接创建
        fix_database
    fi
}

# 备份数据库
backup_database() {
    log_info "备份数据库..."
    BACKUP_DIR="/opt/backups"
    DATE=$(date +%Y%m%d_%H%M%S)
    mkdir -p $BACKUP_DIR
    
    if [ -f "/opt/point-rewards/point-rewards-backend/app.db" ]; then
        cp /opt/point-rewards/point-rewards-backend/app.db $BACKUP_DIR/app_$DATE.db
        log_success "数据库备份完成: app_$DATE.db"
    else
        log_error "数据库文件不存在"
        exit 1
    fi
}

# 重启服务
restart_services() {
    log_info "重启所有服务..."
    
    # 重启后端服务
    if command_exists supervisorctl; then
        if pgrep -f supervisord >/dev/null && supervisorctl status point-rewards-backend >/dev/null 2>&1; then
            supervisorctl restart point-rewards-backend
            log_success "后端服务已重启"
        else
            log_warning "后端服务未配置或Supervisor未运行"
        fi
    else
        log_warning "supervisorctl 不可用"
    fi
    
    # 重启Nginx
    if command_exists systemctl; then
        if systemctl is-active --quiet nginx 2>/dev/null; then
            systemctl restart nginx
            log_success "Nginx 已重启"
        else
            log_warning "Nginx 服务未运行"
        fi
    else
        log_warning "systemctl 不可用"
    fi
}

# 查看状态
show_status() {
    echo "=========================================="
    echo "           服务状态"
    echo "=========================================="
    
    # Nginx状态
    echo "🌐 Nginx 状态:"
    if command_exists systemctl && systemctl is-active --quiet nginx 2>/dev/null; then
        echo "  ✅ 运行中"
    else
        echo "  ❌ 未运行或不可用"
    fi
    
    # 后端服务状态
    echo ""
    echo "🔧 后端服务状态:"
    if command_exists supervisorctl && pgrep -f supervisord >/dev/null; then
        if supervisorctl status point-rewards-backend >/dev/null 2>&1; then
            supervisorctl status point-rewards-backend
        else
            echo "  ❌ 未配置"
        fi
    else
        echo "  ❌ Supervisor不可用或未运行"
    fi
    
    # 端口监听
    echo ""
    echo "🔌 端口监听:"
    if command_exists ss; then
        ss -tlnp 2>/dev/null | grep -E ':80|:443|:5000' | while read line; do
            echo "  $line"
        done || echo "  无监听端口"
    elif command_exists netstat; then
        netstat -tlnp 2>/dev/null | grep -E ':80|:443|:5000' | while read line; do
            echo "  $line"
        done || echo "  无监听端口"
    else
        echo "  网络工具不可用"
    fi
    
    # 磁盘使用
    echo ""
    echo "💾 磁盘使用:"
    if command_exists df; then
        df -h 2>/dev/null | grep -E "/$|/opt|/var" || df -h 2>/dev/null | head -2
    else
        echo "  df命令不可用"
    fi
}

# 查看日志
show_logs() {
    echo "=========================================="
    echo "           服务日志"
    echo "=========================================="
    
    echo "🔍 后端错误日志 (最新10行):"
    if [ -f "/var/log/point-rewards-backend-error.log" ]; then
        tail -10 /var/log/point-rewards-backend-error.log
    else
        echo "  日志文件不存在"
    fi
    
    echo ""
    echo "🔍 Nginx错误日志 (最新10行):"
    if [ -f "/var/log/nginx/error.log" ]; then
        tail -10 /var/log/nginx/error.log
    else
        echo "  日志文件不存在"
    fi
    
    echo ""
    echo "实时查看日志命令:"
    echo "  sudo tail -f /var/log/point-rewards-backend-error.log"
    echo "  sudo tail -f /var/log/nginx/error.log"
}

# 测试访问
test_access() {
    echo "=========================================="
    echo "           访问测试"
    echo "=========================================="
    
    # 域名配置
    MOBILE_DOMAIN="points.eternalmoon.com.cn"
    ADMIN_DOMAIN="dashboard.eternalmoon.com.cn"
    
    echo "🌐 测试域名访问:"
    
    if command_exists curl; then
        # 测试HTTP
        echo "  HTTP 测试:"
        http_mobile=$(curl -s -o /dev/null -w "%{http_code}" "http://$MOBILE_DOMAIN" 2>/dev/null || echo "000")
        http_admin=$(curl -s -o /dev/null -w "%{http_code}" "http://$ADMIN_DOMAIN" 2>/dev/null || echo "000")
        
        echo "    移动端 http://$MOBILE_DOMAIN: $http_mobile"
        echo "    管理后台 http://$ADMIN_DOMAIN: $http_admin"
        
        # 测试HTTPS
        echo "  HTTPS 测试:"
        https_mobile=$(curl -s -k -o /dev/null -w "%{http_code}" "https://$MOBILE_DOMAIN" 2>/dev/null || echo "000")
        https_admin=$(curl -s -k -o /dev/null -w "%{http_code}" "https://$ADMIN_DOMAIN" 2>/dev/null || echo "000")
        
        echo "    移动端 https://$MOBILE_DOMAIN: $https_mobile"
        echo "    管理后台 https://$ADMIN_DOMAIN: $https_admin"
        
        # 测试API
        echo "  API 测试:"
        api_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:5000" 2>/dev/null || echo "000")
        echo "    后端API http://localhost:5000: $api_code"
    else
        echo "  curl命令不可用，跳过网络测试"
    fi
    
    echo ""
    echo "📋 状态码说明:"
    echo "  200: 正常"
    echo "  301/302: 重定向 (通常HTTP->HTTPS)"
    echo "  404: 页面未找到"
    echo "  502/503: 服务错误"
    echo "  000: 连接失败"
}

# 故障排查
troubleshoot() {
    log_info "运行故障排查..."
    show_status
    echo ""
    show_logs
}

# 查看数据库数据
view_data() {
    log_info "查看数据库数据..."
    cd /opt/point-rewards/point-rewards-backend 2>/dev/null || {
        log_error "后端目录不存在，请先运行部署"
        exit 1
    }
    
    if [ ! -d "venv" ]; then
        log_error "虚拟环境不存在，请先运行部署"
        exit 1
    fi
    
    if [ ! -f "utils/view_data.py" ]; then
        log_error "数据查看脚本不存在"
        exit 1
    fi
    
    source venv/bin/activate
    
    if [ -n "$2" ]; then
        if command_exists python3; then
            python3 utils/view_data.py "$2"
        elif command_exists python; then
            python utils/view_data.py "$2"
        else
            log_error "未找到Python解释器"
            deactivate
            exit 1
        fi
    else
        echo "数据库查看工具使用方法:"
        echo "  bash manage.sh view-data users          # 查看用户表"
        echo "  bash manage.sh view-data prizes         # 查看奖品表"
        echo "  bash manage.sh view-data redemptions    # 查看兑换记录表"
        echo "  bash manage.sh view-data summary        # 显示数据汇总"
    fi
    
    deactivate
}

# 显示部署信息
show_info() {
    echo "=========================================="
    echo "           部署信息"
    echo "=========================================="
    
    MOBILE_DOMAIN="points.eternalmoon.com.cn"
    ADMIN_DOMAIN="dashboard.eternalmoon.com.cn"
    
    echo "🌐 访问地址:"
    echo "  移动端: https://$MOBILE_DOMAIN"
    echo "  管理后台: https://$ADMIN_DOMAIN"
    echo ""
    echo "📁 重要目录:"
    echo "  项目目录: /opt/point-rewards"
    echo "  Web目录: /var/www/"
    echo "  日志目录: /var/log/"
    echo "  备份目录: /opt/backups"
    echo ""
    echo "🔧 管理命令:"
    echo "  查看服务: sudo supervisorctl status"
    echo "  重启后端: sudo supervisorctl restart point-rewards-backend"
    echo "  重启Nginx: sudo systemctl restart nginx"
    echo "  查看日志: sudo tail -f /var/log/point-rewards-backend-error.log"
    echo ""
    echo "🗃️ 数据库:"
    if [ -f "/opt/point-rewards/point-rewards-backend/app.db" ]; then
        echo "  ✅ 数据库文件存在"
        ls -la /opt/point-rewards/point-rewards-backend/app.db
    else
        echo "  ❌ 数据库文件不存在"
    fi
}

# 主函数
main() {
    case "$1" in
        "deploy")
            check_permissions "$1"
            deploy
            ;;
        "deploy-robust")
            check_permissions "$1"
            deploy_robust
            ;;
        "cleanup")
            check_permissions "$1"
            cleanup
            ;;
        "init-db")
            check_permissions "$1"
            init_database
            ;;
        "fix-db")
            check_permissions "$1"
            fix_database
            ;;
        "create-admin")
            check_permissions "$1"
            create_admin
            ;;
        "backup")
            check_permissions "$1"
            backup_database
            ;;
        "restart")
            check_permissions "$1"
            restart_services
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "test")
            test_access
            ;;
        "troubleshoot")
            troubleshoot
            ;;
        "info")
            show_info
            ;;
        "view-data")
            view_data "$@"
            ;;
        "help"|"--help"|"-h"|"")
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi