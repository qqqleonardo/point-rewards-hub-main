# 积分兑换管理后台

一个现代化的积分兑换系统管理后台，基于React + TypeScript构建。

## 功能特性

- 🎯 **仪表板** - 系统数据总览和统计图表
- 👥 **用户管理** - 用户列表、积分管理、权限设置  
- 🎁 **奖品管理** - 奖品CRUD、库存管理、分类管理
- 📋 **兑换管理** - 兑换记录、状态管理、发货管理
- 📊 **数据统计** - 实时数据展示和报表

## 技术栈

- **前端框架**: React 18 + TypeScript
- **构建工具**: Vite
- **UI组件**: shadcn/ui + Tailwind CSS
- **状态管理**: React Query + Context API
- **路由**: React Router v6
- **HTTP客户端**: Axios
- **图表**: Recharts

## 快速开始

### 安装依赖

```bash
npm install
```

### 启动开发服务器

```bash
npm run dev
```

应用将在 `http://localhost:3001` 启动

### 构建生产版本

```bash
npm run build
```

## 项目结构

```
src/
├── components/          # 可复用组件
│   ├── ui/             # shadcn/ui 基础组件
│   └── Layout.tsx      # 布局组件
├── contexts/           # React Context
├── hooks/              # 自定义 Hooks
├── lib/                # 工具函数和配置
├── pages/              # 页面组件
├── types/              # TypeScript 类型定义
└── App.tsx             # 主应用组件
```

## 环境要求

- Node.js >= 16
- npm >= 8

## 管理员登录

使用具有管理员权限的账号登录系统。

## API 集成

后台通过REST API与后端服务通信，所有API请求都包含JWT身份验证。

## 开发说明

- 使用TypeScript进行类型安全开发
- 遵循React最佳实践和Hooks模式
- 使用React Query进行数据获取和缓存
- 响应式设计，支持移动端和桌面端