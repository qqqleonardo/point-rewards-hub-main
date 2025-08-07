# eternalmoon.com.cn 积分兑换平台部署检查清单

## 部署前检查 ✅

### 服务器准备
- [ ] 服务器有公网 IP 地址
- [ ] 域名已解析到服务器 IP
- [ ] 服务器操作系统为 Ubuntu 20.04+ 或 CentOS 8+
- [ ] 服务器内存至少 2GB，推荐 4GB+
- [ ] 服务器磁盘空间至少 20GB
- [ ] 可以通过 SSH 连接到服务器
- [ ] 服务器可以访问互联网

### 域名和 DNS
- [ ] eternalmoon.com.cn 域名已购买并可以管理 DNS 记录
- [ ] A 记录已配置:
  - [ ] points.eternalmoon.com.cn → 服务器 IP
  - [ ] dashboard.eternalmoon.com.cn → 服务器 IP
- [ ] DNS 解析已生效 (可用 nslookup 或 dig 检查)
  ```bash
  nslookup points.eternalmoon.com.cn
  nslookup dashboard.eternalmoon.com.cn
  ```

### 本地文件准备
- [ ] 项目文件已准备完整
- [ ] 确认包含三个主要目录: point-rewards-backend, point-rewards-frontend, point-rewards-admin-web
- [ ] 备份原始项目文件
- [ ] 上传项目文件到服务器或准备 Git 仓库

## 自动部署使用

### 快速部署 (推荐)
```bash
# 1. 上传项目文件到服务器
scp -r point-rewards-hub-main/ user@your-server:/tmp/

# 2. 连接到服务器
ssh user@your-server

# 3. 切换到项目目录
cd /tmp/point-rewards-hub-main

# 4. 给脚本执行权限
chmod +x deploy.sh

# 5. 运行自动部署脚本（无需参数，域名已预配置）
sudo bash deploy.sh
```

### 部署后自动检查
脚本会自动检查以下项目：
- [ ] 系统包更新完成
- [ ] 必需软件安装完成
- [ ] Python 虚拟环境创建成功
- [ ] 后端依赖安装完成
- [ ] 前端构建完成
- [ ] SSL 证书获取/创建成功
- [ ] Nginx 配置正确
- [ ] 服务正常启动
- [ ] 端口监听正常
- [ ] HTTP/HTTPS 访问测试通过

## 手动部署检查 (如不使用自动脚本)

### 后端部署检查
- [ ] Python 3.8+ 已安装
- [ ] 虚拟环境创建成功: `/opt/point-rewards/point-rewards-backend/venv`
- [ ] requirements.txt 依赖安装完成
- [ ] .env 环境配置文件已创建
- [ ] 数据库初始化完成
- [ ] 管理员账户已创建
- [ ] Supervisor 配置文件已创建: `/etc/supervisor/conf.d/point-rewards-backend.conf`
- [ ] 后端服务启动成功: `supervisorctl status point-rewards-backend`
- [ ] 后端服务监听 5000 端口: `netstat -tlnp | grep 5000`

### 前端部署检查
- [ ] Node.js 18+ 和 npm 已安装
- [ ] 移动端前端构建成功: `point-rewards-frontend/dist/`
- [ ] 管理后台构建成功: `point-rewards-admin-web/dist/`
- [ ] 构建文件复制到 Web 目录: 
  - [ ] `/var/www/points.eternalmoon.com.cn/`
  - [ ] `/var/www/dashboard.eternalmoon.com.cn/`
- [ ] 文件权限设置正确: `www-data:www-data`

### SSL 证书检查
- [ ] Let's Encrypt 证书获取成功，或
- [ ] 自签名证书创建成功
- [ ] 证书文件路径正确
- [ ] 证书权限设置正确

### Nginx 配置检查
- [ ] Nginx 已安装并启动
- [ ] 配置文件已创建: `/etc/nginx/sites-available/point-rewards`
- [ ] 配置文件已启用: `/etc/nginx/sites-enabled/point-rewards`
- [ ] Nginx 配置语法检查通过: `nginx -t`
- [ ] HTTP 到 HTTPS 重定向配置正确
- [ ] API 代理配置正确
- [ ] 静态文件服务配置正确

### 系统服务检查
- [ ] 防火墙配置完成 (端口 22, 80, 443 开放)
- [ ] Nginx 服务自启动已启用: `systemctl is-enabled nginx`
- [ ] Supervisor 服务自启动已启用: `systemctl is-enabled supervisor`
- [ ] 备份脚本已创建并添加到 crontab

## 部署后验证 ✅

### 基本功能测试
- [ ] 移动端首页可以访问: `https://points.eternalmoon.com.cn`
- [ ] 管理后台可以访问: `https://dashboard.eternalmoon.com.cn`
- [ ] API 健康检查: 
  - [ ] `curl https://points.eternalmoon.com.cn/api/health`
  - [ ] `curl https://dashboard.eternalmoon.com.cn/api/health`
- [ ] HTTPS 证书有效且浏览器显示安全图标
- [ ] HTTP 自动重定向到 HTTPS

### 移动端功能测试
- [ ] 用户注册功能正常
- [ ] 用户登录功能正常
- [ ] 积分查询功能正常
- [ ] 奖品列表显示正常
- [ ] 奖品兑换功能正常
- [ ] 邀请好友功能正常 (复制链接可用)
- [ ] 个人资料编辑功能正常

### 管理后台功能测试
- [ ] 管理员登录功能正常
- [ ] 用户管理功能正常
- [ ] 奖品管理功能正常
- [ ] 兑换记录查看正常
- [ ] 数据统计显示正常
- [ ] 文件上传功能正常

### 性能和监控检查
- [ ] 页面加载速度正常 (< 3秒)
- [ ] API 响应时间正常 (< 1秒)
- [ ] 服务器资源使用正常 (CPU < 80%, 内存 < 80%)
- [ ] 日志文件正常写入
- [ ] 备份脚本测试成功

### 安全性检查
- [ ] 强密码策略已实施
- [ ] 敏感信息不在日志中暴露
- [ ] HTTPS 强制跳转工作正常
- [ ] 防火墙规则配置正确
- [ ] 系统及时更新到最新版本

## 常见问题排查

### 后端服务无法启动
```bash
# 查看 supervisor 状态
sudo supervisorctl status

# 查看后端错误日志
sudo tail -f /var/log/point-rewards-backend-error.log

# 手动测试后端
cd /opt/point-rewards/point-rewards-backend
source venv/bin/activate
python run.py
```

### 前端页面无法访问
```bash
# 检查 Nginx 状态
sudo systemctl status nginx

# 检查 Nginx 配置
sudo nginx -t

# 查看 Nginx 错误日志
sudo tail -f /var/log/nginx/error.log
```

### SSL 证书问题
```bash
# 检查证书状态
sudo certbot certificates

# 测试证书续期
sudo certbot renew --dry-run

# 检查证书文件权限
ls -la /etc/letsencrypt/live/yourdomain.com/
```

### API 请求失败
```bash
# 测试后端直接访问
curl http://localhost:5000/api/health

# 测试 Nginx 代理
curl https://yourdomain.com/api/health

# 检查防火墙
sudo ufw status  # Ubuntu
sudo firewall-cmd --list-all  # CentOS
```

## 维护检查清单 (定期执行)

### 每日检查
- [ ] 服务状态正常
- [ ] 磁盘空间充足
- [ ] 错误日志无异常

### 每周检查
- [ ] 系统更新检查
- [ ] 备份文件完整性检查
- [ ] 性能指标监控

### 每月检查
- [ ] SSL 证书有效期检查
- [ ] 安全更新应用
- [ ] 日志清理和轮转
- [ ] 数据库优化

## 应急处理

### 服务器宕机
1. 检查服务器状态和网络连接
2. 重启相关服务
3. 查看系统日志确定原因
4. 必要时恢复备份数据

### 数据丢失
1. 停止所有服务避免进一步损坏
2. 从最近备份恢复数据
3. 验证数据完整性
4. 重启服务并测试功能

### 安全事件
1. 立即隔离受影响系统
2. 分析日志确定攻击向量
3. 修复安全漏洞
4. 更新密码和密钥
5. 监控异常活动

---

**备注**: 
- 请根据实际部署情况调整检查项目
- 建议建立监控告警系统
- 定期练习应急恢复流程
- 保持部署文档的及时更新