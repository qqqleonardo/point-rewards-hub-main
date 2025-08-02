#!/bin/bash
# 数据库迁移快速操作脚本
# 使用方法: ./db_migration.sh [action] [message]

set -e

# 配置
BACKEND_DIR="/opt/point-rewards/point-rewards-backend"
BACKUP_DIR="/opt/backups"
LOG_FILE="/var/log/db-migration.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$LOG_FILE"
}

# 检查环境
check_environment() {
    if [ ! -d "$BACKEND_DIR" ]; then
        log_error "后端目录不存在: $BACKEND_DIR"
        exit 1
    fi
    
    cd "$BACKEND_DIR"
    
    if [ ! -f "app.db" ]; then
        log_error "数据库文件不存在: app.db"
        exit 1
    fi
    
    if [ ! -d "venv" ]; then
        log_error "虚拟环境不存在"
        exit 1
    fi
    
    log_info "环境检查通过"
}

# 备份数据库
backup_database() {
    local backup_name="app_backup_$(date +%Y%m%d_%H%M%S).db"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    mkdir -p "$BACKUP_DIR"
    cp "$BACKEND_DIR/app.db" "$backup_path"
    
    log_success "数据库已备份至: $backup_path"
    echo "$backup_path"
}

# 激活虚拟环境
activate_venv() {
    source "$BACKEND_DIR/venv/bin/activate"
    log_info "虚拟环境已激活"
}

# 停止服务
stop_service() {
    if command -v supervisorctl >/dev/null 2>&1; then
        supervisorctl stop point-rewards-backend
        log_info "后端服务已停止"
    else
        log_warning "supervisorctl 未找到，请手动停止服务"
    fi
}

# 启动服务
start_service() {
    if command -v supervisorctl >/dev/null 2>&1; then
        supervisorctl start point-rewards-backend
        sleep 3
        if supervisorctl status point-rewards-backend | grep -q "RUNNING"; then
            log_success "后端服务已启动"
        else
            log_error "后端服务启动失败"
        fi
    else
        log_warning "supervisorctl 未找到，请手动启动服务"
    fi
}

# 检查服务状态
check_service() {
    if command -v supervisorctl >/dev/null 2>&1; then
        supervisorctl status point-rewards-backend
    fi
    
    # 简单的健康检查
    if command -v curl >/dev/null 2>&1; then
        if curl -f -s http://localhost:5000/api/health >/dev/null 2>&1; then
            log_success "API 健康检查通过"
        else
            log_warning "API 健康检查失败"
        fi
    fi
}

# 创建迁移
create_migration() {
    local message="$1"
    if [ -z "$message" ]; then
        log_error "请提供迁移描述信息"
        exit 1
    fi
    
    check_environment
    activate_venv
    
    log_info "创建迁移: $message"
    flask db migrate -m "$message"
    
    log_success "迁移文件已创建"
    log_info "请检查生成的迁移文件是否正确"
}

# 执行迁移
run_migration() {
    check_environment
    
    # 备份数据库
    backup_file=$(backup_database)
    
    activate_venv
    
    # 检查当前状态
    log_info "当前数据库版本:"
    flask db current
    
    log_info "待执行的迁移:"
    flask db show
    
    # 确认执行
    read -p "确认执行迁移? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "迁移已取消"
        exit 0
    fi
    
    # 停止服务
    stop_service
    
    # 执行迁移
    log_info "执行数据库迁移..."
    if flask db upgrade; then
        log_success "数据库迁移成功"
    else
        log_error "数据库迁移失败"
        log_info "正在恢复备份..."
        cp "$backup_file" "$BACKEND_DIR/app.db"
        log_warning "数据库已恢复到迁移前状态"
        start_service
        exit 1
    fi
    
    # 重启服务
    start_service
    
    # 验证结果
    log_info "验证迁移结果:"
    flask db current
    check_service
    
    log_success "迁移完成！"
}

# 回滚操作
rollback_migration() {
    local target_revision="$1"
    
    check_environment
    
    # 备份数据库
    backup_file=$(backup_database)
    
    activate_venv
    
    # 显示迁移历史
    log_info "迁移历史:"
    flask db history
    
    if [ -n "$target_revision" ]; then
        log_info "回滚到版本: $target_revision"
    else
        log_info "回滚到上一个版本"
    fi
    
    # 确认回滚
    read -p "确认执行回滚? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "回滚已取消"
        exit 0
    fi
    
    # 停止服务
    stop_service
    
    # 执行回滚
    log_info "执行数据库回滚..."
    if [ -n "$target_revision" ]; then
        flask db downgrade "$target_revision"
    else
        flask db downgrade
    fi
    
    log_success "数据库回滚成功"
    
    # 重启服务
    start_service
    
    # 验证结果
    log_info "验证回滚结果:"
    flask db current
    check_service
    
    log_success "回滚完成！"
}

# 检查数据库状态
check_database() {
    check_environment
    activate_venv
    
    echo "=== 数据库状态检查 ==="
    
    log_info "当前迁移版本:"
    flask db current
    
    log_info "迁移历史:"
    flask db history -r "current:current+3"
    
    log_info "数据库完整性检查:"
    sqlite3 "$BACKEND_DIR/app.db" "PRAGMA integrity_check;"
    
    log_info "表信息:"
    sqlite3 "$BACKEND_DIR/app.db" ".tables"
    
    log_info "数据统计:"
    cd "$BACKEND_DIR"
    python utils/view_data.py summary
}

# 紧急恢复
emergency_restore() {
    log_warning "执行紧急恢复操作..."
    
    # 停止服务
    stop_service
    
    # 查找最新备份
    latest_backup=$(ls -t "$BACKUP_DIR"/app_*.db 2>/dev/null | head -1)
    if [ -z "$latest_backup" ]; then
        log_error "未找到备份文件"
        exit 1
    fi
    
    log_info "恢复备份文件: $latest_backup"
    cp "$latest_backup" "$BACKEND_DIR/app.db"
    
    # 重启服务
    start_service
    
    log_success "紧急恢复完成"
}

# 显示帮助
show_help() {
    echo "数据库迁移工具"
    echo ""
    echo "用法:"
    echo "  $0 create \"迁移描述\"    - 创建新的迁移文件"
    echo "  $0 migrate              - 执行数据库迁移"
    echo "  $0 rollback [版本号]     - 回滚数据库"
    echo "  $0 status              - 检查数据库状态"
    echo "  $0 emergency           - 紧急恢复"
    echo ""
    echo "示例:"
    echo "  $0 create \"添加用户头像字段\""
    echo "  $0 migrate"
    echo "  $0 rollback"
    echo "  $0 rollback 2175629dc2dd"
    echo "  $0 status"
    echo "  $0 emergency"
}

# 主函数
main() {
    case "${1:-help}" in
        "create")
            create_migration "$2"
            ;;
        "migrate")
            run_migration
            ;;
        "rollback")
            rollback_migration "$2"
            ;;
        "status")
            check_database
            ;;
        "emergency")
            emergency_restore
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log_error "未知操作: $1"
            show_help
            exit 1
            ;;
    esac
}

# 检查权限
if [[ $EUID -ne 0 ]]; then
    log_error "此脚本需要 root 权限运行，请使用 sudo"
    exit 1
fi

# 创建日志目录
mkdir -p "$(dirname "$LOG_FILE")"

# 执行主函数
main "$@"