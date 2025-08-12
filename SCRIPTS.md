# 脚本文件说明

## 📋 主要脚本

### 🎯 manage.sh - 统一管理工具 ⭐
**最重要的脚本，提供所有管理功能**

```bash
bash manage.sh help           # 查看所有命令
sudo bash manage.sh deploy    # 一键部署
bash manage.sh status         # 查看状态
bash manage.sh test           # 测试访问
```

### 🚀 deploy.sh - 标准部署脚本
自动化部署整个系统，包含数据库初始化

```bash
sudo bash deploy.sh
```

### 🔄 deploy-robust.sh - 增强部署脚本
支持断点续传和错误恢复的部署脚本

```bash
sudo bash deploy-robust.sh
sudo bash deploy-robust.sh --resume    # 断点续传
sudo bash deploy-robust.sh --force     # 强制重新部署
```

### 🧹 cleanup-deployment.sh - 完整清理脚本
清理所有 eternalmoon 相关的部署文件

```bash
sudo bash cleanup-deployment.sh
```

## 📁 项目文件结构

### 保留的脚本文件
```
point-rewards-hub-main/
├── manage.sh                  # ⭐ 统一管理工具（推荐使用）
├── deploy.sh                  # 标准部署
├── deploy-robust.sh           # 增强部署
├── cleanup-deployment.sh      # 完整清理
├── README.md                  # 用户指南
└── SCRIPTS.md                 # 本文件
```

### 已移除的脚本文件
这些功能已整合到 `manage.sh` 中：
- ~~cleanup-old-deployment.sh~~ → `manage.sh cleanup`
- ~~troubleshoot-deployment.sh~~ → `manage.sh troubleshoot`
- ~~fix-supervisor.sh~~ → `manage.sh restart`
- ~~debug-backend.sh~~ → `manage.sh troubleshoot`
- ~~init-database.sh~~ → `manage.sh init-db`

## 🎯 推荐使用方式

### 首次部署
```bash
# 1. 配置DNS解析
# 2. 一键部署
sudo bash manage.sh deploy

# 部署命令将自动创建数据库和管理员账户。
```

### 日常维护
```bash
# 查看状态
bash manage.sh status

# 测试访问
bash manage.sh test

# 查看日志
bash manage.sh logs

# 重启服务
sudo bash manage.sh restart
```

### 故障排查
```bash
# 运行完整诊断
bash manage.sh troubleshoot

# 查看详细信息
bash manage.sh info
```

### 系统清理
```bash
# 完整清理重新部署
sudo bash manage.sh cleanup
sudo bash manage.sh deploy
```

## 🔧 脚本特点

### manage.sh 优势
- ✅ 统一入口，简化操作
- ✅ 智能权限检查
- ✅ 彩色输出，清晰易读
- ✅ 完整的帮助信息
- ✅ 集成所有常用功能

### deploy.sh vs deploy-robust.sh
| 功能 | deploy.sh | deploy-robust.sh |
|------|-----------|------------------|
| 部署速度 | 快 | 较慢 |
| 断点续传 | ❌ | ✅ |
| 错误恢复 | ❌ | ✅ |
| 状态跟踪 | ❌ | ✅ |
| 适用场景 | 首次部署 | 生产环境 |

## 💡 最佳实践

1. **优先使用 manage.sh**
   ```bash
   # 推荐
   sudo bash manage.sh deploy
   
   # 而不是
   sudo bash deploy.sh
   ```

2. **生产环境使用增强部署**
   ```bash
   sudo bash manage.sh deploy-robust
   ```

3. **定期备份**
   ```bash
   bash manage.sh backup
   ```

4. **监控服务状态**
   ```bash
   bash manage.sh status
   ```

## 🆘 故障处理流程

1. **首先运行状态检查**
   ```bash
   bash manage.sh status
   ```

2. **测试网站访问**
   ```bash
   bash manage.sh test
   ```

3. **查看错误日志**
   ```bash
   bash manage.sh logs
   ```

4. **运行故障排查**
   ```bash
   bash manage.sh troubleshoot
   ```

5. **如需重新部署**
   ```bash
   sudo bash manage.sh cleanup
   sudo bash manage.sh deploy
   ```