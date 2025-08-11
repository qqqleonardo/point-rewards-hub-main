# 积分兑换平台

一个基于 Flask + React 的积分兑换系统，包含移动端用户界面和管理后台。

## 📋 项目组成

- **point-rewards-backend**: Flask API 后端服务
- **point-rewards-frontend**: React 移动端用户界面
- **point-rewards-admin-web**: React 管理后台界面
- **manage.sh**: 统一管理工具（推荐）

## 🚀 快速开始

### 一键部署
```bash
# 1. 上传项目到服务器
cd point-rewards-hub-main

# 2. 配置DNS解析
# points.eternalmoon.com.cn      A    YOUR_SERVER_IP
# dashboard.eternalmoon.com.cn   A    YOUR_SERVER_IP

# 3. 一键部署（自动处理所有配置）
sudo bash manage.sh deploy

# 4. 创建管理员账户
sudo bash manage.sh create-admin
```

**默认管理员信息**:
- 账号: `admin`
- 密码: `Eternalmoon.com1`

## 🔧 manage.sh 统一管理工具

### 查看帮助
```bash
bash manage.sh help              # 查看所有可用命令
```

### 部署命令
```bash
sudo bash manage.sh deploy       # 标准部署（推荐）
sudo bash manage.sh deploy-robust # 增强部署（生产环境）
sudo bash manage.sh cleanup      # 完整清理
```

### 维护命令
```bash
sudo bash manage.sh init-db      # 初始化数据库
sudo bash manage.sh fix-db       # 修复数据库问题（推荐）
sudo bash manage.sh create-admin # 创建管理员账户
sudo bash manage.sh backup       # 备份数据库
sudo bash manage.sh restart      # 重启服务
```

### 诊断命令
```bash
bash manage.sh status            # 查看服务状态
bash manage.sh logs              # 查看服务日志
bash manage.sh test              # 测试网站访问
bash manage.sh troubleshoot      # 运行故障排查
bash manage.sh info              # 显示部署信息
bash manage.sh view-data summary # 查看数据库数据汇总
```

## 🌐 访问地址

- **移动端**: https://points.eternalmoon.com.cn
- **管理后台**: https://dashboard.eternalmoon.com.cn

## 🛠️ 系统要求

- **操作系统**: Ubuntu 20.04 LTS 或 CentOS 8+
- **内存**: 最低 2GB，推荐 4GB+
- **磁盘**: 最低 20GB 可用空间
- **网络**: 公网 IP 地址
- **软件**: Python 3.8+, Node.js 18+, Nginx, Supervisor (可选)

**注意**: manage.sh 会自动检测和安装所需依赖。

## 📚 详细文档

- [部署文档](Docs/DEPLOYMENT.md) - 完整部署指南
- [部署检查清单](Docs/DEPLOYMENT_CHECKLIST.md) - 部署验证清单
- [脚本说明](SCRIPTS.md) - 所有脚本的使用说明
- [完整用户指南](Docs/README.md) - 详细用户文档

## ⚠️ 故障排查

### 标准排查流程
```bash
# 1. 运行完整诊断（推荐首先执行）
bash manage.sh troubleshoot

# 2. 查看服务状态
bash manage.sh status

# 3. 测试网站访问
bash manage.sh test

# 4. 查看错误日志
bash manage.sh logs
```

### 常见问题快速解决

#### 网站无法访问
```bash
bash manage.sh status          # 检查服务状态
bash manage.sh test            # 测试访问
sudo bash manage.sh restart    # 重启服务
```

#### 数据库问题
```bash
# 一键修复数据库和管理员账户
sudo bash manage.sh fix-db
```

#### 服务启动失败
```bash
bash manage.sh logs            # 查看错误日志
sudo bash manage.sh restart    # 重启服务
```

#### 完整重新部署
```bash
# 如果问题严重，完整重新部署
sudo bash manage.sh cleanup
sudo bash manage.sh deploy
```

## 💡 最佳实践

1. **使用 manage.sh 进行所有操作**
   ```bash
   # 推荐使用统一管理工具
   sudo bash manage.sh deploy
   bash manage.sh status
   ```

2. **定期监控和维护**
   ```bash
   # 建议每日执行
   bash manage.sh status
   bash manage.sh test
   ```

3. **备份策略**
   ```bash
   # 重要操作前备份
   sudo bash manage.sh backup
   ```

4. **故障处理流程**
   - 首先运行: `bash manage.sh troubleshoot`
   - 查看状态: `bash manage.sh status`
   - 必要时重启: `sudo bash manage.sh restart`

## 🚀 更新部署

```bash
# 1. 备份当前版本
sudo bash manage.sh backup

# 2. 更新代码
git pull origin main  # 或重新上传文件

# 3. 重新部署
sudo bash manage.sh deploy

# 4. 重启服务
sudo bash manage.sh restart
```

---

**重要提醒**: 
- **优先使用 `manage.sh` 统一管理工具**，它集成了所有必要功能
- 遇到问题时，首先运行 `bash manage.sh troubleshoot` 进行诊断
- 所有命令都经过测试，确保在生产环境中的可靠性
- 如需帮助，请查看 `bash manage.sh help` 或相关文档

**技术支持**: 如果在使用过程中遇到问题，请先运行故障排查命令获取详细信息。