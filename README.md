# 积分兑换平台

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

## 🔧 常用命令

```bash
# 查看服务状态
bash manage.sh status

# 测试网站访问
bash manage.sh test

# 重启服务
sudo bash manage.sh restart

# 查看日志
bash manage.sh logs

# 故障排查
bash manage.sh troubleshoot
```

## 🌐 访问地址

- **移动端**: https://points.eternalmoon.com.cn
- **管理后台**: https://dashboard.eternalmoon.com.cn

## 📚 详细文档

- [完整用户指南](Docs/README.md)
- [脚本说明](SCRIPTS.md)
- [部署检查清单](Docs/DEPLOYMENT_CHECKLIST.md)

## ⚠️ 常见问题

### 网站无法访问
```bash
# 1. 检查服务状态
bash manage.sh status

# 2. 测试访问
bash manage.sh test

# 3. 查看错误日志
bash manage.sh logs

# 4. 如果问题持续，重新部署
sudo bash manage.sh deploy
```

### 后端服务问题
```bash
# 重启服务
sudo bash manage.sh restart

# 如果问题持续，重新部署会自动修复所有配置
sudo bash manage.sh deploy
```

### 管理员账户问题
```bash
# 创建管理员账户
sudo bash manage.sh create-admin
```

---

**提示**: 部署脚本已集成所有修复功能，如遇问题可直接重新部署！