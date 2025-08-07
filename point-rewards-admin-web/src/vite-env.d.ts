/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL: string
  // 可以在这里添加其他环境变量的类型定义
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}