# 积分兑换平台

一个完整的积分兑换系统，包含移动端用户界面和管理后台。

## 🚀 快速部署

### 一键部署
```bash
# 1. 克隆或上传项目到服务器
git clone <repository-url>
cd point-rewards-hub-main

# 2. 一键部署
sudo bash manage.sh deploy
```

### 系统要求
- **操作系统**: Ubuntu 20.04+ 或 CentOS 8+
- **内存**: 最低 2GB，推荐 4GB+
- **磁盘**: 最低 20GB 可用空间
- **网络**: 公网 IP 地址

### DNS 配置
在域名管理面板添加以下 A 记录：
```
points.eternalmoon.com.cn      A    YOUR_SERVER_IP
dashboard.eternalmoon.com.cn   A    YOUR_SERVER_IP
```

## 📋 管理命令

### 部署管理
```bash
# 标准部署
sudo bash manage.sh deploy

# 增强部署（支持断点续传）
sudo bash manage.sh deploy-robust

# 完整清理
sudo bash manage.sh cleanup
```

### 系统维护
```bash
# 查看服务状态
bash manage.sh status

# 重启所有服务
sudo bash manage.sh restart

# 初始化数据库
sudo bash manage.sh init-db

# 创建管理员账户
sudo bash manage.sh create-admin

# 备份数据库
sudo bash manage.sh backup
```

### 故障排查
```bash
# 测试网站访问
bash manage.sh test

# 查看服务日志
bash manage.sh logs

# 运行故障排查
bash manage.sh troubleshoot

# 查看部署信息
bash manage.sh info
```

## 🌐 访问地址

部署完成后可通过以下地址访问：

- **移动端用户界面**: https://points.eternalmoon.com.cn
- **管理后台**: https://dashboard.eternalmoon.com.cn

## 📁 项目结构

```
point-rewards-hub-main/
├── point-rewards-backend/     # Flask API 后端
├── point-rewards-frontend/    # React 移动端
├── point-rewards-admin-web/   # React 管理后台
├── deploy.sh                  # 标准部署脚本
├── deploy-robust.sh           # 增强部署脚本
├── cleanup-deployment.sh      # 清理脚本
├── manage.sh                  # 统一管理工具
└── Docs/                      # 详细文档
```

## 🔧 手动管理

### 服务管理
```bash
# 查看服务状态
sudo supervisorctl status
sudo systemctl status nginx

# 重启服务
sudo supervisorctl restart point-rewards-backend
sudo systemctl restart nginx

# 查看日志
sudo tail -f /var/log/point-rewards-backend-error.log
sudo tail -f /var/log/nginx/error.log
```

### 数据库管理
```bash
# 进入后端目录
cd /opt/point-rewards/point-rewards-backend

# 激活虚拟环境
source venv/bin/activate

# 创建管理员账户
python create_admin_simple.py

# 备份数据库
cp app.db /opt/backups/app_$(date +%Y%m%d_%H%M%S).db
```

## 🛠️ 故障排查

### 常见问题

**1. 网站无法访问**
```bash
# 检查服务状态
bash manage.sh status

# 测试访问
bash manage.sh test

# 查看日志
bash manage.sh logs
```

**2. 后端服务无法启动**
```bash
# 运行故障排查
bash manage.sh troubleshoot

# 手动启动测试
cd /opt/point-rewards/point-rewards-backend
source venv/bin/activate
python run.py
```

**3. SSL 证书问题**
```bash
# 检查证书状态
sudo certbot certificates

# 重新获取证书
sudo certbot --nginx -d points.eternalmoon.com.cn -d dashboard.eternalmoon.com.cn
```

### 日志文件位置
- 后端服务日志: `/var/log/point-rewards-backend-error.log`
- Nginx 日志: `/var/log/nginx/error.log`
- SSL 续期日志: `/var/log/ssl-renewal.log`

## 🔒 安全建议

1. **定期更新系统**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **定期备份数据**
   ```bash
   bash manage.sh backup
   ```

3. **监控系统状态**
   ```bash
   bash manage.sh status
   ```

4. **查看访问日志**
   ```bash
   sudo tail -f /var/log/nginx/access.log
   ```

## 📚 详细文档

- [部署检查清单](Docs/DEPLOYMENT_CHECKLIST.md)
- [详细部署指南](Docs/DEPLOYMENT.md)

## 🆘 获取帮助

```bash
# 显示所有可用命令
bash manage.sh help

# 查看部署信息
bash manage.sh info
```

如果遇到问题，请：
1. 运行 `bash manage.sh troubleshoot` 进行故障排查
2. 查看 `bash manage.sh logs` 了解错误详情
3. 检查 DNS 解析和防火墙配置

---

**注意**: 部署过程中请确保服务器有稳定的网络连接，并且已正确配置 DNS 解析。